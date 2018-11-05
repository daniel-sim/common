require 'rails_helper'

describe PR::Common::Redactable do
  class RedactableDummy
    include PR::Common::Redactable

    CALL_PROC_AFTER_REDACTION = -> {}

    attr_accessor :email, :unique_email, :name, :unique_name, :placeheld, :custom, :url,
                  :unique_url, :placeheld_url, :nullifiable

    after_redaction CALL_PROC_AFTER_REDACTION
    after_redaction :call_method_after_redaction

    redactable :email, :email
    redactable :unique_email, :email, unique: true
    redactable :name, :string
    redactable :unique_name, :string, unique: true
    redactable :placeheld, :string, placeholder: "placeholder"
    redactable :custom, :custom, proc: proc { "#{custom}-REDACTED" }
    redactable :url, :url
    redactable :unique_url, :url, unique: true
    redactable :placeheld_url, :url, placeholder: "https://schembri.me"
    redactable :nullifiable, :nil

    def initialize(attributes = {})
      attributes.each { |attr, value| instance_variable_set(:"@#{attr}", value) }
    end

    def update!(attributes = {})
      attributes.each { |attr, value| send(:"#{attr}=", value) }
    end

    def call_method_after_redaction; end
  end

  let(:dummy) do
    RedactableDummy.new(
      email: "help@schembri.me",
      unique_email: "jamie@pluginuseful.com",
      name: "Plug in Useful",
      unique_name: "Jamie Schembri",
      placeheld: "This string should be redacted with a pre-defined placeholder",
      custom: "Custom",
      nullifiable: "Foo",
      url: "pluginuseful.com",
      unique_url: "pluginuseful.com",
      placeheld_url: "pluginuseful.com"
    )
  end

  describe "#redact!" do
    it "changes email to a non-unique redacted email based on support email" do
      dummy.redact!

      expect(dummy.email).to eq "REDACTED@pluginuseful.com"
    end

    it "changes unique_email to a unique redacted email with a UUID based on support email" do
      dummy.redact!

      expect(dummy.unique_email).to match(
        /\AREDACTED-\w{8}-\w{4}-\w{4}-\w{4}-\w{12}@pluginuseful\.com\z/
      )
    end

    it "changes name to a redacted string" do
      dummy.redact!

      expect(dummy.name).to eq "REDACTED"
    end

    it "changes unique_name to a unique redacted string with a UUID" do
      dummy.redact!

      expect(dummy.unique_name).to match(/\AREDACTED-\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\z/)
    end

    it "changes placeheld to a redacted string with a preset placeholder" do
      dummy.redact!

      expect(dummy.placeheld).to eq "placeholder"
    end

    it "changes nullifiable to nil" do
      dummy.redact!

      expect(dummy.nullifiable).to eq nil
    end

    it "changes url to a unique redacted url" do
      dummy.redact!

      expect(dummy.url).to eq "https://pluginuseful.com/REDACTED"
    end

    it "changes unique url to a unique redacted url" do
      dummy.redact!

      expect(dummy.unique_url).to match(
        %r{\Ahttps://pluginuseful.com/REDACTED-\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\z}
      )
    end

    it "changes placeheld url to a placeholder url" do
      dummy.redact!

      expect(dummy.placeheld_url).to eq "https://schembri.me"
    end

    it "changes procced to a value based on a given proc" do
      dummy.redact!

      expect(dummy.custom).to eq "Custom-REDACTED"
    end

    it "calls a method defined after redaction" do
      expect(dummy).to receive(:call_method_after_redaction).once

      dummy.redact!
    end

    it "calls a proc defined for after redaction" do
      expect(RedactableDummy::CALL_PROC_AFTER_REDACTION).to receive(:call).once

      dummy.redact!
    end
  end
end
