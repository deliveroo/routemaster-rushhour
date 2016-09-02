web: bundle exec puma -C config/puma.rb config/config.ru
worker: foreman start -f Procfile.sidekiq -m worker=$SIDEKIQ_WORKERS
