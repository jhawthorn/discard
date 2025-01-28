# frozen_string_literal: true

require "discard/configuration"

module Discard
  module Configure
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
