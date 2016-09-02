web: bundle exec unicorn -c config/unicorn.rb config/config.ru
worker: bundle exec sidekiq -r ./config/sidekiq.rb -c 1
