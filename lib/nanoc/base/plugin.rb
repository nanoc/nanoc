module Nanoc

  # Nanoc::Plugin is the superclass for all plugins, such as filters,
  # layout processors and data sources.
  class Plugin

    class << self

      attr_accessor :identifiers # :nodoc:

      # Sets or returns the identifiers for this plugin.
      #
      # When given a list of identifier symbols, sets the identifiers for
      # this plugin. When given nothing, returns an array of identifier
      # symbols for this plugin.
      def identifiers(*idents)
        @identifiers = [] unless instance_variables.include?('@identifiers')
        idents.empty? ? @identifiers : @identifiers = idents
      end

      # Sets or returns the identifier for this plugin.
      #
      # When given an identifier symbols, sets the identifier for this plugin.
      # When given nothing, returns the identifier for this plugin.
      def identifier(ident=nil)
        @identifiers = [] unless instance_variables.include?('@identifiers')
        ident.nil? ? @identifiers.first : identifiers(ident)
      end

      # Returns the the plugin with the given name. Only subclasses of this
      # class will be searched. For example, calling this method on
      # Nanoc::Filter will cause only Nanoc::Filter subclasses to be searched.
      def named(name)
        # Initialize list of classes if necessary
        @classes ||= {}
        @classes[self] ||= {}

        # Find plugin
        @classes[self][name] ||= find(self, :identifiers, name.to_sym)
      end

      # Returns all subclasses of the given class.
      def find_all(superclass)
        classes = []
        ObjectSpace.each_object(Class) { |c| classes << c if c < superclass }
        classes
      end

      # Returns all subclasses of the given class, where the attribute named
      # +attribute+ is an array containing +value+.
      def find(superclass, attribute, value)
        find_all(superclass).find { |c| c.send(attribute).include?(value) }
      end

    end

  end

end
