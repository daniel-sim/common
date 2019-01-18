namespace 'common' do
  namespace 'webhooks' do
    desc "Recreate all webhooks based on config. Optionally pass a comma-separated list of domains."
    task :recreate, [:shops_file] => [:environment] do |_, args|
      FileUtils.mkdir_p(Rails.root.join('tmp'))
      Rails.logger = Logger.new Rails.root.join('tmp', 'common-webhooks-recreate.log')

      shops = if args[:shops_file].present?
                Shop.where( shopify_domain: File
                                            .read(args[:shops_file])
                                            .split('\s')
                                            .map(&:strip))
              else
                Shop.installed
              end

      puts PR::Common::WebhookService.recreate_webhooks!(shops)
    end
  end

  namespace "schedule" do
    desc "Collect sustained analytics"
    task sustained_analytics: :environment do
      PR::Common::SustainedAnalyticsJob.perform_later
    end
  end
end
