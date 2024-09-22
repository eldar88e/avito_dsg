class MainPopulateJob < ApplicationJob
  queue_as :default

  def perform(**args)
    user = find_user(args)
    PopulateExcelJob.perform_now(user: user)
    AddAdJob.perform_now(user: user)
    AddImageJob.perform_now(user: user)
  end
end
