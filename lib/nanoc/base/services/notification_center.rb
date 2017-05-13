# frozen_string_literal: true

module Nanoc::Int
  # Provides a way to send notifications between objects. It allows blocks
  # associated with a certain notification name to be registered; these blocks
  # will be called when the notification with the given name is posted.
  #
  # It is a slightly different implementation of the Observer pattern; the
  # table of subscribers is not stored in the observable object itself, but in
  # the notification center.
  #
  # @api private
  class NotificationCenter
    class << self
      # Adds the given block to the list of blocks that should be called when
      # the notification with the given name is received.
      #
      # @param [String, Symbol] name The name of the notification that will
      #   cause the given block to be called.
      #
      # @param [String, Symbol, nil] id An identifier for the block. This is
      #   only used to be able to remove the block (using the remove method)
      #   later. Can be nil, but this is not recommended because it prevents
      #   the given notification block from being unregistered.
      #
      # @yield [*args] Will be executed with the arguments passed to {.post}
      #
      # @return [void]
      def on(name, id = nil, &block)
        initialize_if_necessary(name)

        # Add observer
        @notifications[name] << { id: id, block: block }
      end

      # Posts a notification with the given name and the given arguments.
      #
      # @param [String, Symbol] name The name of the notification that should
      #   be posted.
      #
      # @param args Arguments that wil be passed to the blocks handling the
      #   notification.
      #
      # @return [void]
      def post(name, *args)
        initialize_if_necessary(name)

        # Notify all observers
        @notifications[name].each do |observer|
          observer[:block].call(*args)
        end
      end

      # Removes the block with the given identifier from the list of blocks
      # that should be called when the notification with the given name is
      # posted.
      #
      # @param [String, Symbol] name The name of the notification that should
      #   no longer be registered.
      #
      # @param [String, Symbol] id The identifier of the block that should be
      #   removed.
      #
      # @return [void]
      def remove(name, id)
        initialize_if_necessary(name)

        # Remove relevant observers
        @notifications[name].reject! { |i| i[:id] == id }
      end

      # @api private
      #
      # @return [void]
      def reset
        @notifications = nil
      end

      private

      def initialize_if_necessary(name)
        @notifications ||= {}       # name => observers dictionary
        @notifications[name] ||= [] # list of observers
      end
    end
  end
end
