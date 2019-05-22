require 'rack-affiliates'
require 'sidekiq'
require 'sassc-rails'

module PR
  module Common
    class Engine < ::Rails::Engine
      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot, dir: 'spec/factories'
      end
      initializer :append_migrations do |app|
        unless app.root.to_s.match root.to_s
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path

            ActiveRecord::Migrator.migrations_paths << expanded_path
          end
        end
      end
      initializer :enable_affiliates do |app|
        app.middleware.use Rack::Affiliates
        app.middleware.use PR::Common::AffiliateRedirect
      end
      initializer :configure_active_job do |app|
        if app.config.active_job.queue_adapter != :sidekiq
          raise 'Ensure you have config.active_job.queue_adapter = :sidekiq in your application.rb'
        end
      end
    end
  end
end
