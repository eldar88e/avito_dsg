class MainPopulateJob < ApplicationJob
  queue_as :default

  def perform(**args)
    user = find_user(args)
    PopulateExcelJob.perform_now(user: user)
    AddAdAndImageJob.perform_now(user: user)
  end
end
