class AddAdAndImageJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers
  MAX_THREADS = 4

  def perform(**args)
    user     = find_user(args) || User.first  #TODO убрать User.first
    store    = user.stores.first
    settings = user.settings.pluck(:var, :value).to_h
    parts    = Part.includes(:models, :model_part)
    brands   = Brand.all
    dsg_var  = settings['dsg'].split(', ')
    threads  = []
    mutex    = Mutex.new

    brands.each do |brand|
      brand_title = brand.title == 'Luk' ? brand.title.upcase : ''
      dsg_var.each do |dsg|
        dsg_title = dsg.present? ? dsg : ''
        parts.each do |part|
          part.models.each do |model|
            years_slices = [*model.start_year..model.end_year].each_slice(MAX_THREADS).to_a
            years_slices.each do |years|
              thread = Thread.new do
                years.each do |year|
                  title = make_title(part, dsg_title, brand_title, model, year)
                  #mutex.synchronize do
                    ad    = find_or_save_ad(store: store, user: user, title: title, file_id: title, adable: part)
                  #end
                  form_image(ad, store, settings, part) if ad.image.blank? || args[:update]
                end
              end
              threads << thread
            end
            threads.each(&:join)
          end
        end
      end
    rescue => e
      binding.pry
    end
    nil
  end

  private

  def find_or_save_ad(**args)
    ad = args[:user].ads.find_by(title: args[:title], deleted: 0)

    if ad && args[:rewrite]
      ad.update(deleted: 1)
      ad = nil
    end

    ad || Ad.create(args)
  end

  def make_title(part, dsg_title, brand_title, model, year)
    template_title = part.template_title
    return "#{part.title} #{brand_title} #{model.sub_brand.title} #{model.title} #{year}" if template_title.blank?

    template_title.sub('[part]', part.title).sub('[sub_brand]', model.sub_brand.title).sub('[model]', model.title)
                  .sub('[year]', year.to_s).sub('[dsg_title]', dsg_title).sub('[brand_title]', brand_title)
                  .sub('[model_part]', "#{part.model_part.title}").squeeze(' ')
  end

  def form_image(ad, store, settings, part)
    return Rails.logger.error "Part #{part.id} has no photos" if part.photos.blank?

    w_service   = WatermarkService.new(store: store, settings: settings, images: part.photos)
    dynamic_img = [:rotate, nil].sample
    image       = w_service.add_watermarks(:rotate)
    save_image(ad, image)
  end

  def save_image(ad, image)
    image.format = 'JPEG'
    img_blob     = image.to_blob
    img_io       = StringIO.new(img_blob)
    ad.image.attach(io: img_io, filename: "#{ad.title.gsub(' ', '_')}.jpg", content_type: 'image/jpeg')
  end

  def save_image_old(ad, image)
    Tempfile.open(%w[image .jpg]) do |temp_img|
      image.write(temp_img.path)
      temp_img.flush

      file_name = "#{ad.title.gsub(' ', '_')}.jpg"
      ad.image.attach(io: File.open(temp_img.path), filename: file_name, content_type: 'image/jpeg')
    end
  end
end
