class PopulateExcelJob < ApplicationJob
  include Rails.application.routes.url_helpers
  queue_as :default

  def perform
    user      = User.first
    store     = Store.first
    settings  = user.settings.pluck(:var, :value).to_h
    xlsx_path = "./game_lists/#{store.var}.xlsx"
    workbook  = FastExcel.open
    worksheet = workbook.add_worksheet
    worksheet.append_row(
      %w[Id AdType Address Title Description Condition Price AllowEmail ManagerName ContactPhone Originality
         Availability Brand OEM TransmissionSparePartType ImageUrls GoodsType Category ProductType SparePartType]
    )
    years        = [*2008..2023]
    parts        = Part.includes(:model_part)
    brands       = Brand.all
    sub_brands   = SubBrand.includes(:models)
    originality  = 'Оригинал'
    availability = 'В наличии'
    dsg_variants = settings['dsg'].split(', ')
    store.addresses.each do |address_model|
      address = address_model.store_address
      years[0..0].each do |year|      # TODO убрать [0..0]
        brands.each do |brand|
          brand_title = brand.title == 'luk' ? ' LUK' : nil
          dsg_variants.each do |dsg|
            dsg_title = dsg.present? ? " #{dsg}" : nil
            parts.each do |part|
              prices = (part.min_price...part.max_price).step(100).to_a
              sub_brands.each do |sub_brand|
                sub_brand.models.each do |model|
                  title   = make_title(part, dsg_title, brand_title, sub_brand, model, year)
                  ad      = { store: store, user: user, title: title, file_id: title, adable: part }
                  ad_db   = save_ad(ad, store, settings, part)
                  ad_type = store.ad_type.split(', ').sample
                  worksheet.append_row(
                    [ad_db.id, ad_type, "#{address}#{rand(3..161)}", title, make_description(title, store, part),
                     store.condition, prices.sample, store.allow_email, store.manager_name, store.contact_phone,
                     originality, availability, brand.title, '', part.part_type, make_image(ad_db), 'Запчасти',
                     'Запчасти и аксессуары', 'Для автомобилей', 'Трансмиссия и привод']
                  )
                end
              end
            end
          end
        end
      end
    end

    content = workbook.read_string
    File.open(xlsx_path, 'wb') { |f| f.write(content) }

    domain = Rails.env.production? ? 'server.open-ps.ru' : 'localhost:3000'
    msg    = "✅ File http://#{domain}#{xlsx_path[1..-1]} is updated!"
    broadcast_notify(msg)
    TelegramService.call(user, msg)
  rescue => e
    Rails.logger.error("Error #{self.class} || #{e.message}")
    TelegramService.call(user,"Error #{self.class} || #{e.message}")
  end

  private

  def make_title(part, dsg_title, brand_title, sub_brand, model, year)
    ["#{part.title}#{dsg_title}#{brand_title}",
     part.model_part.title,
     'восстановленный',
     sub_brand.title,
     "#{model.title},",
     year
    ].join(' ')
  end

  def save_ad(ad_attributes, store, settings, part, rewrite=false)
    ad = Ad.find_by(title: ad_attributes[:title], deleted: 0)
    if rewrite || !ad
      ad        = Ad.create(ad_attributes)
      w_service = WatermarkService.new(store: store, settings: settings, sub_part: part)
      return unless w_service.image

      image = w_service.add_watermarks
      save_image(ad: ad, image: image, part: part, store_id: store.id)
    end
    ad
  end

  def save_image(**args)
    temp_img = Tempfile.new(%w[image .jpg])
    args[:image].write(temp_img.path)
    temp_img.flush

    args[:ad].image.attach(io: File.open(temp_img.path), filename: args[:ad].title, content_type: 'image/jpeg',
                                 metadata: { title: args[:name] })
    args[:ad].save
    temp_img.close
    temp_img.unlink
  end

  def make_image(ad)
    image = ad&.image
    return unless image

    params = Rails.env.production? ? { host: 'avito.dsg7.ru' } : { host: 'localhost', port: 3000 }
    return unless image.attached?

    return rails_blob_url(image, params) if image.blob.service_name != "amazon"

    bucket = Rails.application.credentials.dig(:aws, :bucket)
    key    = image.blob.key
    "https://#{bucket}.s3.amazonaws.com/#{key}"
  end

  def make_description(title, store, zap)
    desc_product = store.description
    desc_product.gsub('[title]', title).gsub('[manager]', store.manager_name)
                .gsub('[sub_desc]', zap.description)
                .squeeze(' ').strip
  end
end
