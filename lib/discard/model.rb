module Discard
  module Model
    extend ActiveSupport::Concern

    included do
      scope :kept, ->{ undiscarded }
      scope :undiscarded, ->{ where(discarded_at: nil) }
      scope :discarded, ->{ where.not(discarded_at: nil) }
      scope :with_discarded, ->{ unscope(where: :discarded_at) }
    end

    def discarded?
      !!discarded_at
    end

    def discard
      touch(:discarded_at) unless discarded?
    end
  end
end
