class PartsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_part, only: [:edit, :update, :destroy]

  def index
    @parts = Part.all.order(:title, :model_part_id)
  end

  def new
    @part = Part.new
    render turbo_stream: [turbo_stream.replace(:new_part, partial: 'parts/new')]
  end

  def create
    @part = Part.new(part_params)
    if @part.save
      msg = "Запчасть #{@part.title} была успешно добавлена."
      render turbo_stream: [
        turbo_stream.replace(:new_part, partial: 'parts/new_btn'),
        turbo_stream.after(:new_part, partial: 'parts/part', locals: { part: @part }),
        success_notice(msg)
      ]
    else
      error_notice(@part.errors.full_messages)
    end
  end

  def edit; end

  def update
    if @part.update(part_params)
      if params[:part][:remove_photos].present?
        params[:part][:remove_photos].each do |photo_id|
          @part.photos.find(photo_id).purge
        end
      end
      # binding.pry
      # params[:part][:photos].each { |photo| photo.present? && @part.photos.attach(photo) }

      flash[:success] = "Запчасть #{@part.title} была успешно обновлена."
      redirect_to parts_path # @sub_part
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

  def save_images
    img_params.each { |_, value| value.reject(&:blank?).present? && @part.photos.attach(value) }
  end

  def img_params
    params.require(:part).permit(photos: [])
  end

  def set_part
    @part = Part.find(params[:id])
  end

  def part_params
    for_permit = %i[title description part_type model_part_id min_price max_price]
    for_permit << { photos: [] } if params[:part][:photos].reject(&:blank?).present?
    params.require(:part).permit(*for_permit)
  end
end
