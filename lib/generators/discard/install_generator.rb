# frozen_string_literal: true

module Discard
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("install/templates", __dir__)

      desc "rails generate discard:install"

      def copy_initializer_file
        template "discard.rb.tt", "config/initializers/discard.rb"
      end
    end
  end
end
