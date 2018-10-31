require 'rails_helper'

describe PR::Common::Redactable do
  class RedactableDummy
    include PR::Common::Redactable

    CALL_PROC_AFTER_REDACTION = -> {}

    attr_accessor :email, :unique_email, :name, :unique_name, :placeheld, :custom

    after_redaction CALL_PROC_AFTER_REDACTION
    after_redaction :call_method_after_redaction

    redactable :email, :email
    redactable :unique_email, :email, unique: true
    redactable :name, :string
    redactable :unique_name, :string, unique: true
    redactable :placeheld, :string, placeholder: "placeholder"
    redactable :custom, :custom, proc: proc { "#{custom}-REDACTED" }

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
      custom: "Custom"
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
