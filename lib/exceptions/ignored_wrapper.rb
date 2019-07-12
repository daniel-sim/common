module Exceptions
  class IgnoredWrapper < StandardError
    extend Forwardable

    attr_reader :original_exception

    def initialize(original_exception)
      @original_exception = original_exception
      @_rollbar_do_not_report = true # undocumented, see lib/rollbar/notifier.rb#ignored?
    end

    def_delegators :original_exception, :backtrace, :backtrace_locations,
                   :cause, :exception, :full_message, :inspect, :message, :to_s

    def original_class
      original_exception.class
    end
  end
end
