# AddAdJob.perform_now(user: User.first)

class AddAdJob < ApplicationJob
  queue_as :default

  def perform(**args)
    user     = find_user(args) || User.first  #TODO убрать User.first
    stores   = [args[:store] || user.stores].flatten
    settings = user.settings.pluck(:var, :value).to_h
    parts    = Part.includes(:models, :model_part)
    brands   = Brand.all
    dsg_var  = settings['dsg'].split(', ')

    stores.each do |store|
      brands.each do |brand|
        brand_title = brand.title == 'Luk' ? brand.title.upcase : ''
        dsg_var.each do |dsg|
          parts.each do |part|
            part.models.each do |model|
              [*model.start_year..model.end_year].each do |year|
                title = make_title(part, dsg, brand_title, model, year)
                find_or_save_ad(store: store, user: user, title: title, adable: part)
              end
            end
          end
        end
      end
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

    ad || Ad.create!(args)
  end

  def make_title(part, dsg_title, brand_title, model, year)
    template_title = part.template_title
    return "#{part.title} #{brand_title} #{model.sub_brand.title} #{model.title} #{year}" if template_title.blank?

    template_title.sub('[part]', part.title).sub('[sub_brand]', model.sub_brand.title).sub('[model]', model.title)
                  .sub('[year]', year.to_s).sub('[dsg_title]', dsg_title).sub('[brand_title]', brand_title)
                  .sub('[model_part]', "#{part.model_part.title}").squeeze(' ')
  end
end
