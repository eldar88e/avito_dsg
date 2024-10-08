class PopulateExcelJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(**args)
    user      = args[:store]&.user || find_user(args) || User.first     # TODO убрать User.first
    stores    = [args[:store] || user.stores].flatten
    workbook  = FastExcel.open
    worksheet = workbook.add_worksheet
    worksheet.append_row(
      %w[Id AdType Address Title Description Condition Price AllowEmail ManagerName ContactPhone Originality
         Availability Brand OEM TransmissionSparePartType ImageUrls GoodsType Category ProductType SparePartType]
    )

    stores.each do |store|
      store.addresses.each do |i|
        address = i.store_address
        ads     = store.ads.active_ads.includes(:adable).with_attached_image
        ads.find_each(batch_size: 200).each do |ad|
          ad_type = store.ad_type.split(', ').sample
          part    = ad.adable
          prices  = (part.min_price...part.max_price).step(100).to_a  #TODO Вынести в ad
          brand   = ad.title.match?(/LUK/) ? 'Luk' : 'VAG'            #TODO Вынести в ad
          worksheet.append_row(
            [ad.id, ad_type, "#{address}#{rand(3..161)}", ad.title, make_description(ad.title, store, part),
             store.condition, prices.sample, store.allow_email, store.manager_name, store.contact_phone,
             'Оригинал', 'В наличии', brand, rand(400000000..499999999), part.part_type, make_image(ad), 'Запчасти',
             'Запчасти и аксессуары', 'Для автомобилей', 'Трансмиссия и привод']  # TODO хардкод убрать в Store или Part
          )
        end
      end
      content   = workbook.read_string
      xlsx_path = "./game_lists/#{store.var}.xlsx"
      File.open(xlsx_path, 'wb') { |f| f.write(content) }
      domain = Rails.env.production? ? 'avito.dsg7.ru' : 'localhost:3000'
      msg    = "✅ File http://#{domain}#{xlsx_path[1..-1]} is updated!"
      broadcast_notify(msg)
      TelegramService.call(user, msg)
    end

    nil
  rescue => e
    Rails.logger.error("Error #{self.class} || #{e.message}")
    TelegramService.call(user,"Error #{self.class} || #{e.message}")
  end

  private

  def make_image(ad)
    image = ad.image
    if image.nil? || image.blob.nil?
      Rails.logger.error('Not existing attach or blob!')
      return ''
    end

    params = Rails.env.production? ? { host: 'avito.dsg7.ru' } : { host: 'localhost', port: 3000 }
    return rails_blob_url(image, params) if image.blob.service_name != "amazon"

    bucket = Rails.application.credentials.dig(:aws, :bucket)
    key    = image.blob.key
    "https://#{bucket}.s3.amazonaws.com/#{key}"
  end

  def make_description(title, store, part)
    desc_product = store.description
    desc_product.gsub('[title]', title).gsub('[manager]', store.manager_name)
                .gsub('[sub_desc]', part.description)
                .squeeze(' ').strip
  end
end
