# frozen_string_literal: true

module Discard
  class Configuration
    attr_accessor :discard_column

    def initialize
      self.discard_column = :discarded_at
    end
  end
end
