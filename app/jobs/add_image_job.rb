# AddImageJob.perform_now(user: User.first)

class AddImageJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(**args)
    user      = find_user(args) || User.first  #TODO убрать User.first
    settings  = args[:settings] || user.settings.pluck(:var, :value).to_h
    stores    = [args[:store] || user.stores].flatten
    addr_args = { active: true }
    count     = 0
    addr_args[:id] = args[:address_id].to_i if args[:address_id].present?

    stores.each do |store|
      store.addresses.where(addr_args).each do |address|
        # TODO пока нет возможности получить address.ads
        ads = store.ads.includes(:adable).where(deleted: 0).with_attached_image
        ads.find_in_batches(batch_size: 200).each do |batch_ads|
          batch_ads.each do |ad|
            next if ad.image.attached? && !args[:clean]

            save_image(ad, settings)
            count += 1
          end
        end
      end
      msg = "🏞 Added #{count} image(s) for #{store.manager_name}"
      broadcast_notify(msg)
      TelegramService.call(user, msg)
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
