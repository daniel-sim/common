module PR
  module Common
    class SustainedAnalyticsJob < ApplicationJob
      queue_as :low_priority

      def perform
        with_analytics { PR::Common::SustainedAnalyticsService.perform }
      end
    end
  end
end
