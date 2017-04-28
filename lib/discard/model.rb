module Discard
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :discard_column
      self.discard_column = :discarded_at

      scope :kept, ->{ undiscarded }
      scope :undiscarded, ->{ where(discard_column => nil) }
      scope :discarded, ->{ where.not(discard_column => nil) }
      scope :with_discarded, ->{ unscope(where: discard_column) }
    end

    def discarded?
      !!self[self.class.discard_column]
    end

    def discard
      unless discarded?
        self[self.class.discard_column] = Time.current
      end
      save
    end

    def undiscard
      self[self.class.discard_column] = nil
      save
    end
  end
end
