# frozen_string_literal: true

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
      class_attribute :discard_by_column

      self.discard_column = :discarded_at
      self.discard_by_column = :discarded_by_id

      scope :kept, ->{ undiscarded }
      scope :undiscarded, ->{ where(discard_column => nil) }
      scope :discarded, ->{ where.not(discard_column => nil) }
      scope :with_discarded, ->{ unscope(where: discard_column) }
      scope :discarded_by, -> (user_id){ where(discard_by_column => user_id) }

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
      #   Person.where(age: 0..16).discard_all(current_user)
      def discard_all(user = nil)
        kept.each { |record| record.discard(user) }
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

    # Discard the record in the database
    #
    # @param [User] a User or equivelant instance
    # @return [Boolean] true if successful, otherwise false
    def discard(user = nil)
      return if discarded?
      run_callbacks(:discard) do
        public_send("#{self.class.discard_column}=", Time.current)
        public_send("#{self.class.discard_by_column}=", user.try(:id))
        save(validate: false)
      end
    end

    # Discard the record in the database
    #
    # There's a series of callbacks associated with #discard!. If the
    # <tt>before_discard</tt> callback throws +:abort+ the action is cancelled
    # and #discard! raises {Discard::RecordNotDiscarded}.
    #
    # @return [Boolean] true if successful
    # @raise {Discard::RecordNotDiscarded}
    def discard!(user = nil)
      discard(user) || _raise_record_not_discarded
    end

    # Undiscard the record in the database
    #
    # @return [Boolean] true if successful, otherwise false
    def undiscard
      return unless discarded?
      run_callbacks(:undiscard) do
        public_send("#{self.class.discard_column}=", nil)
        public_send("#{self.class.discard_by_column}=", nil)
        save(validate: false)
      end
    end

    # Discard the record in the database
    #
    # There's a series of callbacks associated with #undiscard!. If the
    # <tt>before_undiscard</tt> callback throws +:abort+ the action is cancelled
    # and #undiscard! raises {Discard::RecordNotUndiscarded}.
    #
    # @return [Boolean] true if successful
    # @raise {Discard::RecordNotUndiscarded}
    def undiscard!
      undiscard || _raise_record_not_undiscarded
    end

    private

    def _raise_record_not_discarded
      raise ::Discard::RecordNotDiscarded.new("Failed to discard the record", self)
    end

    def _raise_record_not_undiscarded
      raise ::Discard::RecordNotUndiscarded.new("Failed to undiscard the record", self)
    end
  end
end
