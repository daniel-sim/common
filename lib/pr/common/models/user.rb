module PR
  module Common
    module Models
      # This is a stake in the ground to gradually improve our messy User code
      # As much as possible should be in Common
      # We will work towards this by including this module in our apps and moving generic pieces here
      # So please include PR::Common::Models::User
      module User
        extend ActiveSupport::Concern

        included do
          include PR::Common::Redactable

          redactable :email, :email, unique: true
          redactable :username, :string, unique: true
          redactable :website, :custom, proc: :website_redactor

          enum provider: { shopify: 0, tictail: 1 }

          [:has_active_charge?, :active_charge?].each do |name|
            send(:define_method, name, -> { self.active_charge })
          end

          def subscription_length
            (DateTime.now - self.charged_at.to_datetime).to_i if self.charged_at
          end
        end

        private

        def website_redactor
          "https://pluginuseful.com/REDACTED-#{SecureRandom.uuid}"
        end

        class_methods do
          # add class methods here
        end
      end
    end
  end
end
