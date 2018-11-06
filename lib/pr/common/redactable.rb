module PR::Common::Redactable
  extend ActiveSupport::Concern

  REDACTED_STRING = 'REDACTED'.freeze

  class_methods do
    attr_reader :redactables
    attr_reader :after_redaction_actions

    # Accepts a proc or symbol detailing what to do after redaction
    def after_redaction(method_name_or_proc)
      @after_redaction_actions ||= []

      @after_redaction_actions << method_name_or_proc
    end

    def redactable(attribute, redactor, options = {})
      @redactables ||= []

      @redactables << OpenStruct.new(
        attribute: attribute,
        redactor: :"redact_#{redactor}",
        options: { attribute: attribute }.merge(options)
      )
    end

    def redact_email(_obj, options = {})
      Settings.support_email.match(/(?<domain>@.*\z)/) do |matches|
        to = REDACTED_STRING.dup
        to << "-#{SecureRandom.uuid}" if options[:unique]

        return "#{to}#{matches[:domain]}"
      end
    end

    def redact_string(_obj, options = {})
      base = options.fetch(:placeholder, REDACTED_STRING)

      return base unless options[:unique]

      "#{base}-#{SecureRandom.uuid}"
    end

    def redact_nil(_obj, _options = {}); end

    # Custom redaction with a proc
    def redact_custom(obj, options)
      the_proc = options[:proc].respond_to?(:call) ? options[:proc] : obj.method(options[:proc])

      obj.instance_exec(&the_proc)
    end
  end

  # Redacts all redactable fields and updates them in the database.
  def redact!
    update!(attributes_for_redaction)

    self.class.after_redaction_actions&.each do |redaction_action|
      redaction_action.respond_to?(:call) ? redaction_action.call : send(redaction_action)
    end
  end

  private

  def attributes_for_redaction
    return {} if self.class.redactables.blank?

    Hash[
      self.class.redactables.map do |redactable|
        new_value = self.class.send(redactable.redactor, self, redactable.options)

        [redactable.attribute, new_value]
      end
    ]
  end
end
