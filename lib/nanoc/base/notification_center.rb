module Nanoc

  # Nanoc::NotificationCenter provides a way to send notifications between
  # objects. It allows blocks associated with a certain notification name to
  # be registered; these blocks will be called when the notification with the
  # given name is posted.
  #
  # It is a slightly different implementation of the Observer pattern; the
  # table of subscribers is not stored in the observable object itself, but in
  # the notification center.
  class NotificationCenter

    # TODO add ability to remove blocks

    class << self

      # Adds the given block to the list of blocks that should be called when
      # the notification with the given name is received.
      def on(name, &block)
        @notifications ||= {}
        @notifications[name] ||= []
        @notifications[name] << block
      end

      # Posts a notification with the given name. All arguments wil be passed
      # to the blocks handling the notification.
      def post(name, *args)
        @notifications ||= {}
        @notifications[name] ||= []
        @notifications[name].each { |p| p.call(*args) }
      end

    end

  end

end
