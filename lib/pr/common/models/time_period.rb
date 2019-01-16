module PR
  module Common
    module Models
      # Shops have multiple time periods.
      # Time periods may not overlap.
      #
      # When a new shop is created:
      # - a new TimePeriod should be created with start_time NOW(), end_time NULL, and kind :installed
      #
      # When a shop is uninstalled:
      # - its current time period's end_time should be set to NOW()
      # - a new TimePeriod should be created with start_time NOW(), end_time NULL, and kind :uninstalled
      #
      # When a shop is reinstalled:
      # - its current time period's end_time should be set to NOW()
      # - a new TimePeriod should be created with start_time NOW(), end_time NULL, and kind :reinstalled
      #
      # When a shop is closed:
      # - its current time period's end_time should be set to NOW()
      # - a new TimePeriod should be created with start_time NOW(), end_time NULL, and kind :reinstalled
      #
      # When a shop is reopened:
      # - its current time period's end_time should be set to NOW()
      # - a new TimePeriod should be created with start_time NOW(), end_time NULL, and kind :reopened
      #
      # - Time periods for a shop should never overlap.
      # - A start_time for a TimePeriod can match an end_time of another.
      # - All TimePeriods except the current one *must* have an end_time set.
      class TimePeriod < ApplicationRecord
        self.table_name = "time_periods"

        scope :not_yet_ended, -> { where("end_time IS NULL OR end_time >= NOW()") }

        belongs_to :shop

        enum kind: { installed: 0,
                     reinstalled: 1,
                     reopened: 2,
                     uninstalled: 3,
                     closed: 4 }
      end
    end
  end
end
