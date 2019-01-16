module PR
  module Common
    module Models
      class TimePeriod < ApplicationRecord
        self.table_name = "time_periods"

        belongs_to :shop

        enum kind: { installed: 0, reinstalled: 1, reopened: 2 }
      end
    end
  end
end
