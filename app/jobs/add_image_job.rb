# AddImageJob.perform_now(user: User.first)

class AddImageJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(**args)
    user     = find_user(args) || User.first  #TODO убрать User.first
    settings = user.settings.pluck(:var, :value).to_h
    stores   = [args[:store] || user.stores].flatten
    stores.each do |store|
      ads = store.ads.includes(:adable).where(deleted: 0).with_attached_image
      ads.find_each(batch_size: 200).each { |ad| save_image(ad, settings) if !ad.image.attached? || args[:update] }
    end

    nil
  end

  private

  def save_image(ad, settings)
    images    = ad.adable.photos
    store     = ad.store
    w_service = WatermarkService.new(store: store, settings: settings, images: images)
    return unless w_service.image

    image        = w_service.add_watermarks(:rotate)      # [:rotate, nil].sample
    image.format = 'JPEG'
    img_blob     = image.to_blob
    img_io       = StringIO.new(img_blob)
    ad.image.attach(io: img_io, filename: "#{ad.title.gsub(/[ ,]/, '_')}.jpg", content_type: 'image/jpeg')
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
