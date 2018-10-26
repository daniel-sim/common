module PR
  module Common
    class ApplicationJob < ActiveJob::Base
      def with_analitics()
        yield
        Analytics.flush
      end
    end
  end
end
