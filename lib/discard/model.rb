module Discard
  # Handles soft deletes of records.
  #
  # Options:
  #
  # - :discard_column - The columns used to track soft delete, defaults to `:discarded_at`.
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

    # :nodoc:
    module ClassMethods
      # Discards the records by instantiating each
      # record and calling its {#discard} method.
      # Each object's callbacks are executed.
      # Returns the collection of objects that were discarded.
      #
      # Note: Instantiation, callback execution, and update of each
      # record can be time consuming when you're discarding many records at
      # once. It generates at least one SQL +UPDATE+ query per record (or
      # possibly more, to enforce your callbacks). If you want to discard many
      # rows quickly, without concern for their associations or callbacks, use
      # #update_all(discarded_at: Time.current) instead.
      #
      # ==== Examples
      #
      #   Person.where(age: 0..18).discard_all
      def discard_all
        kept.each(&:discard)
      end

      # Undiscards the records by instantiating each
      # record and calling its {#undiscard} method.
      # Each object's callbacks are executed.
      # Returns the collection of objects that were undiscarded.
      #
      # Note: Instantiation, callback execution, and update of each
      # record can be time consuming when you're undiscarding many records at
      # once. It generates at least one SQL +UPDATE+ query per record (or
      # possibly more, to enforce your callbacks). If you want to undiscard many
      # rows quickly, without concern for their associations or callbacks, use
      # #update_all(discarded_at: nil) instead.
      #
      # ==== Examples
      #
      #   Person.where(age: 0..18).undiscard_all
      def undiscard_all
        discarded.each(&:undiscard)
      end
    end

    # @return [Boolean] true if this record has been discarded, otherwise false
    def discarded?
      self[self.class.discard_column].present?
    end

    # Discard record
    #
    # @return [Boolean] true if successful, otherwise false
    def discard
      return if discarded?
      run_callbacks(:discard) do
        update_attribute(self.class.discard_column, Time.current)
      end
    end

    # Undiscard record
    #
    # @return [Boolean] true if successful, otherwise false
    def undiscard
      return unless discarded?
      run_callbacks(:undiscard) do
        update_attribute(self.class.discard_column, nil)
      end
    end
  end
end
