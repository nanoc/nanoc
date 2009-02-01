module Nanoc

  # Nanoc::Plugin is the superclass for all plugins, such as filters
  # (Nanoc::Filter), binary filters (Nanoc::BinaryFilter), routers
  # (Nanoc::Router), data sources (Nanoc::DataSource) and VCSes
  # (Nanoc::Extra::VCS). Each plugin has one or more unique identifiers, and
  # several methods in this class provides functionality for finding plugins
  # with given identifiers.
  class Plugin

    MAP = {}

    class << self

      # Sets or returns the identifiers for this plugin.
      #
      # When given a list of identifier symbols, sets the identifiers for
      # this plugin. When given nothing, returns an array of identifier
      # symbols for this plugin.
      def identifiers(*identifiers)
        # Initialize
        if !instance_variables.include?('@identifiers') && !instance_variables.include?(:'@identifiers')
          @identifiers = []
        end

        if identifiers.empty?
          @identifiers
        else
          @identifiers = identifiers
          @identifiers.each { |i| register(i, self) }
        end
      end

      # Sets or returns the identifier for this plugin.
      #
      # When given an identifier symbols, sets the identifier for this plugin.
      # When given nothing, returns the identifier for this plugin.
      def identifier(identifier=nil)
        # Initialize
        if !instance_variables.include?('@identifiers') && !instance_variables.include?(:'@identifiers')
          @identifiers = []
        end

        if identifier.nil?
          @identifiers.first
        else
          @identifiers = [ identifier ]
          register(identifier, self)
        end
      end

      # Registers the given class +klass+ with the given name. This will allow
      # the named method to find the class.
      def register(name, klass)
        MAP[klass.superclass] ||= {}
        MAP[klass.superclass][name.to_sym] = klass
      end

      # Returns the the plugin with the given name. Only subclasses of this
      # class will be searched. For example, calling this method on
      # Nanoc::Filter will cause only Nanoc::Filter subclasses to be searched.
      def named(name)
        MAP[self] ||= {}
        MAP[self][name.to_sym]
      end

    end

  end

end
