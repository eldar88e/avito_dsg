Rails.application.configure do
  config.good_job.execution_mode = :external
  config.good_job.queues = 'default:5'
  config.good_job.enable_cron = true
  config.good_job.smaller_number_is_higher_priority = true
  config.good_job.time_zone = 'Europe/Moscow'

  # Cron jobs
  all = {
    update_feed: {
      cron: "0 1 29 2 *",
      kwargs: { user_id: ENV.fetch("USER_ID") { 1 }.to_i },
      class: "MainPopulateJob",
      set: { priority: 10 }, # additional ActiveJob properties; can also be a lambda/proc e.g. `-> { { priority: [1,2].sample } }`
      description: "Populate excel feed."
    },
    clear: {
      cron: "0 3 29 2 *",
      class: "Clean::MainCleanerJob",
      kwargs: { user_id: ENV.fetch("USER_ID") { 1 }.to_i },
      set: { priority: 10 },
      description: "Job on cleaning unnecessary files, blobs, and attachments"
    }
  }

  production = {
    update_feed: {
      cron: "40 8,21 * * *",
      kwargs: { user_id: ENV.fetch("USER_ID") { 1 }.to_i },
      class: "MainPopulateJob",
      set: { priority: 10 },
      description: "Populate excel feed."
    }
  }

  config.good_job.cron = all # Rails.env.production? ? all.merge(production) : all
end
