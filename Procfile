web: bundle exec puma -C config/puma.rb config/config.ru
worker: bundle exec sidekiq -r ./config/sidekiq.rb -c $SIDEKIQ_CONCURRENCY
