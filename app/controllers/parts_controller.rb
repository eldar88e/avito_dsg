class PartsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_part, only: [:edit, :update, :destroy]
  before_action :set_photos, only: [:edit, :update]
  add_breadcrumb 'Oбъявления', '/parts'

  def index
    @parts = Part.all.order(:title, :model_part_id)
  end

  def new
    @part = Part.new
    render turbo_stream: [turbo_stream.replace(:new_part, partial: 'parts/new')]
  end

  def create
    @part = params[:copy_id].present? ? Part.find(params[:copy_id]).dup : Part.new(part_params)
    if @part.save
      msg = "Запчасть #{@part.title} была успешно добавлена."
      msg.sub!('добавлена', 'скопирована') if params[:copy_id]
      render turbo_stream: [
        turbo_stream.replace(:new_part, partial: 'parts/new_btn'),
        turbo_stream.after(:title_part, partial: 'parts/part', locals: { part: @part }),
        success_notice(msg)
      ]
    else
      error_notice(@part.errors.full_messages)
    end
  end

  def edit
    add_breadcrumb @part.title, edit_part_path(@part)
  end

  def update
    if @part.update(part_params)
      photos = params[:part][:photos]
      return error_notice('Вложений должно быть до 20шт.') if photos.size > 21

      photos.each { |photo| @part.photos.attach(photo) }
      remove_photo

      msg = "Запчасть #{@part.title} была успешно обновлена."
      render turbo_stream: [
        turbo_stream.replace(@part, partial: 'parts/form', locals: { url: part_path(@part), method: :patch }),
        success_notice(msg)
      ]
    else
      error_notice(@part.errors.full_messages)
    end
  end

  def destroy
    if @part.destroy
      msg = "Запчасть #{@part.title} была успешно удаленa."
      render turbo_stream: [ turbo_stream.remove(@part), success_notice(msg)]
    else
      error_notice(@part.errors.full_messages)
    end
  end

  private

  def remove_photo
    photo_ids = params[:part][:remove_photos]
    photo_ids&.each { |photo_id| @part.photos.find(photo_id).purge }
  end

  def set_part
    @part = Part.find(params[:id])
  end

  def set_photos
    @pagy, @photos = pagy(@part.photos.order(created_at: :desc), items: 30)
  end

  def part_params
    params.require(:part).permit(:title, :description, :part_type, :model_part_id, :min_price,
                                 :max_price, :template_title, model_ids: [])
  end
end
