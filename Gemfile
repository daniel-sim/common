source 'https://rubygems.org'

gemspec

gem 'activeresource'
gem 'shopify_app'

group :development, :test do
  gem 'pg'
  gem 'factory_bot_rails'
  gem 'pry-byebug', group: [:development, :test]
  gem 'capistrano-sidekiq'
  gem 'vcr'
  gem 'webmock'
  gem 'simplecov', require: false
end

group :test do
  gem "timecop"
  gem "shoulda-matchers", "4.0.0.rc1" # recommended for Rails 5+
end

gem 'devise'
gem 'rack-affiliates'
gem 'sidekiq'
gem 'config'
gem 'analytics-ruby', '~> 2.0.0', require: 'segment/analytics'
