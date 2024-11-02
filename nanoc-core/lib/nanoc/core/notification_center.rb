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
      DONE = Object.new
      SYNC = Object.new

      def initialize
        @thread = nil

        # name => observers dictionary
        @notifications = Hash.new { |hash, name| hash[name] = [] }

        @queue = Queue.new

        @sync_queue = Queue.new
        on(SYNC, self) { @sync_queue << true }
      end

      def start
        @thread ||= Thread.new do # rubocop:disable Naming/MemoizedInstanceVariableName
          Thread.current.abort_on_exception = true

          loop do
            elem = @queue.pop
            break if DONE.equal?(elem)

            name = elem[0]
            args = elem[1]

            @notifications[name].each do |observer|
              observer[:block].call(*args)
            end
          end
        end
      end

      def stop
        @queue << DONE
        @thread.join
      end

      def force_stop
        @queue << DONE
      end

      def on(name, id = nil, &block)
        @notifications[name] << { id:, block: }
      end

      def remove(name, id)
        @notifications[name].reject! { |i| i[:id] == id }
      end

      def post(name, *args)
        @queue << [name, args]
        self
      end

      def sync
        post(SYNC)
        @sync_queue.pop
      end

      class << self
        def instance
          @_instance ||= new.tap(&:start)
        end

        def on(name, id = nil, &)
          instance.on(name, id, &)
        end

        def post(name, *args)
          instance.post(name, *args)
        end

        def remove(name, id)
          instance.remove(name, id)
        end

        def reset
          instance.stop
          @_instance = nil
        end

        def force_reset
          instance.force_stop
          @_instance = nil
        end

        def sync
          instance.sync
        end
      end
    end
  end
end
