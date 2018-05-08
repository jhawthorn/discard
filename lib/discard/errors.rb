# frozen_string_literal: true

module Discard
  # = Discard Errors
  #
  # Generic exception class.
  class DiscardError < StandardError
  end

  # Raised by {Discard::Model#discard!}
  class RecordNotDiscarded < DiscardError
    attr_reader :record

    def initialize(message = nil, record = nil)
      @record = record
      super(message)
    end
  end

  # Raised by {Discard::Model#undiscard!}
  class RecordNotUndiscarded < DiscardError
    attr_reader :record

    def initialize(message = nil, record = nil)
      @record = record
      super(message)
    end
  end
end
