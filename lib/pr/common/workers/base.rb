module PR
  module Common
    module Workers
      class Base
        include Sidekiq::Worker

        RETRY_COUNT = 2

        sidekiq_options retry: RETRY_COUNT

        sidekiq_retries_exhausted do |message, exception|
          handle_retries_exhausted(message["args"], exception)
        end

        def self.handle_retries_exhausted(args, exception)
          message = "#{self.name} failed after #{RETRY_COUNT} retries."
          notify_rollbar_failed_after_retries(exception, message, *args)
        end

        def self.notify_rollbar_failed_after_retries(exception, message, *extra_args)
          rollbar_method = exception.is_a?(Exceptions::IgnoredWrapper) ? :info : :error

          Rollbar.send rollbar_method, exception, message, *extra_args
        end

        private

        # TODO: move to middleware
        def capture_rails_logger
          return yield if Rails.env.test?

          logger = Logger.new(Rails.root.join("log", "#{self.class.name.underscore}.log"))

          rails_logger = Rails.logger
          Rails.logger = logger
          activerecord_logger = ActiveRecord::Base.logger
          ActiveRecord::Base.logger = logger

          begin
            yield
          ensure
            Rails.logger = rails_logger
            ActiveRecord::Base.logger = activerecord_logger
          end
        end
      end
    end
  end
end
