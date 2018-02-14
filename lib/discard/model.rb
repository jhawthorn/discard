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
      define_model_callbacks :undiscard
    end

    module ClassMethods
      def discard_all
        all.each(&:discard)
      end
      def undiscard_all
        all.each(&:undiscard)
      end
    end

    # @return [true,false] true if this record has been discarded, otherwise false
    def discarded?
      !!self[self.class.discard_column]
    end

    # @return [true,false] true if successful, otherwise false
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

    # @return [true,false] true if successful, otherwise false
    def undiscard
      if discarded?
        with_transaction_returning_status do
          run_callbacks(:undiscard) do
            self[self.class.discard_column] = nil
            save
          end
        end
      end
    end
  end
end
