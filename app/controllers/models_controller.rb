class ModelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_model, only: [:edit, :update, :destroy]
  add_breadcrumb 'Модели', '/models'

  def index
    @models = Model.includes(:sub_brand).order(:sub_brand_id, :title)
  end

  def new
    @model = Model.new
    render turbo_stream: [turbo_stream.replace(:new_model, partial: 'models/new')]
  end

  def create
    @model = Model.new(model_params)
    if @model.save
      msg = "Модель #{@model.title} была успешно добавлена."
      render turbo_stream: [
        turbo_stream.replace(:new_model, partial: 'models/new_btn'),
        turbo_stream.after(:new_model, partial: 'models/model', locals: { model: @model }),
        success_notice(msg)
      ]
    else
      error_notice(@model.errors.full_messages)
    end
  end

  def edit
    add_breadcrumb @model.title, edit_model_path(@model)
  end

  def update
    if @model.update(model_params)
      flash[:success] = "Модель #{@model.title} была успешно обновлена."
      redirect_to models_path
    else
      error_notice(@model.errors.full_messages)
    end
  end

  def destroy
    if @model.destroy
      msg = "Модель #{@model.title} была успешно удаленa."
      render turbo_stream: [turbo_stream.remove(@model), success_notice(msg)]
    else
      error_notice(@model.errors.full_messages)
    end
  end

  private

  def set_model
    @model = Model.find(params[:id])
  end

  def model_params
    params.require(:model).permit(:title, :sub_brand_id, :start_year, :end_year, part_ids: [])
  end
end
