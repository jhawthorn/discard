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

      define_model_callbacks :discard
    end

    module ClassMethods
      def discard_all
        all.each(&:discard)
      end
    end

    def discarded?
      !!self[self.class.discard_column]
    end

    def discard
      unless discarded?
        with_transaction_returning_status do
          run_callbacks(:discard) do
            self[self.class.discard_column] = Time.current
            save
          end
        end
      end
    end

    def undiscard
      self[self.class.discard_column] = nil
      save
    end
  end
end
