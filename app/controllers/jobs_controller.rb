class JobsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_settings, only: [:update_img, :update_products_img, :update_store_test_img]

  def update_store_test_img; end

  def update_img
    clean = params[:clean]
    store = current_user.stores.find_by(active: true, id: params[:store_id])
    return if store.nil?

    AddImageJob.perform_later(user: current_user, store: store, settings: @settings,
                              clean: clean, address_id: params[:address_id])

    msg = "Фоновая задача по #{clean ? 'пересозданию' : 'созданию'} картинок успешно запущена."
    render turbo_stream: [success_notice(msg)]
  end

  def update_products_img
    #AddImageJob.perform_later(user: current_user, settings: @settings, clean: params[:clean])
    #past = params[:clean] ? 'пересозданию' : 'созданию'
    past = '[Нужно реализовать]'
    render turbo_stream: [
      success_notice("Фоновая задача по #{past} картинок для всех Product успешно запущена.")
    ]
  end

  def update_feed
    store = current_user.stores.find_by(active: true, id: params[:store_id])
    if store && PopulateExcelJob.perform_later(store: store)
      msg = "Фоновая задача по обновлению фида для магазина #{store.manager_name} успешно запущена."
      render turbo_stream: [success_notice(msg)]
    else
      error_notice "Ошибка запуска фоновой задачи по обновлению фида, возможно магазин не активен!"
    end
  end

  def update_ban_list
    store = current_user.stores.find_by(active: true, id: params[:store_id])
    if store && CheckAvitoErrorsJob.perform_later(store: store)
      msg = "Фоновая задача по обновлению списка заблокированных объявлений для магазина #{store.manager_name} \
             успешно запущена."
      render turbo_stream: [success_notice(msg)]
    else
      msg = "Ошибка запуска фоновой задачи по обновлению списка заблокированных объявлений для магазина \
             #{store.manager_name}, возможно магазин не активен!"
      error_notice(msg)
    end
  end

  private

  def set_settings
    @settings = current_user.settings.pluck(:var, :value).map { |var, value| [var.to_sym, value] }.to_h
  end
end
