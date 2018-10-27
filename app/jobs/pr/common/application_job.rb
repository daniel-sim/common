module PR
  module Common
    class ApplicationJob < ActiveJob::Base
      def with_analytics()
        yield
        Analytics.flush
      end
    end
  end
end
