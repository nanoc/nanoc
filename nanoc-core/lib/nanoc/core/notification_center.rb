# frozen_string_literal: true

module Nanoc
  module Core
    # Provides a way to send notifications between objects. It allows blocks
    # associated with a certain notification name to be registered; these blocks
    # will be called when the notification with the given name is posted.
    #
    # It is a slightly different implementation of the Observer pattern; the
    # table of subscribers is not stored in the observable object itself, but in
    # the notification center.
    class NotificationCenter
      def initialize
        # name => observers dictionary
        @notifications = Hash.new { |hash, name| hash[name] = [] }
      end

      def on(name, id = nil, &block)
        @notifications[name] << { id:, block: }
      end

      def remove(name, id)
        @notifications[name].reject! { |i| i[:id] == id }
      end

      def post(name, *args)
        @notifications[name].each do |observer|
          observer[:block].call(*args)
        end

        self
      end

      class << self
        def instance
          @_instance ||= new
        end

        def on(name, id = nil, &)
          instance.on(name, id, &)
        end

        def post(name, *)
          instance.post(name, *)
        end

        def remove(name, id)
          instance.remove(name, id)
        end

        def reset
          @_instance = nil
        end
      end
    end
  end
end
