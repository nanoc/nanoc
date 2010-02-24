# encoding: utf-8

module Nanoc3

  # The class responsible for keeping track of all loaded plugins, such as
  # filters ({Nanoc3::Filter}), data sources ({Nanoc3::DataSource}) and VCSes
  # ({Nanoc3::Extra::VCS}).
  class PluginRegistry

    # A module that contains class methods for plugins. It provides functions
    # for setting identifiers, registering plugins and finding plugins. Plugin
    # classes should extend this module.
    module PluginMethods

      # Sets the identifiers for this plugin.
      #
      # @param [Array<Symbol>] identifier A list of identifiers to assign to
      # this plugin.
      #
      # @return [void]
      def identifiers(*identifiers)
        register(self, *identifiers)
      end

      # Sets the identifier for this plugin.
      #
      # @param [Symbol] identifier An identifier to assign to this plugin.
      #
      # @return [void]
      def identifier(identifier)
        register(self, identifier)
      end

      # Registers the given class as a plugin with the given identifier.
      #
      # @param [Class, String] class_or_name The class to register, or a
      # string containing the class name to register.
      #
      # @param [Array<Symbol>] identifiers A list of identifiers to assign to
      # this plugin.
      #
      # @return [void]
      def register(class_or_name, *identifiers)
        # Find plugin class
        klass = self
        klass = klass.superclass while klass.superclass.respond_to?(:register)

        # Register
        registry = Nanoc3::PluginRegistry.instance
        registry.register(klass, class_or_name, *identifiers)
      end

      # Returns the plugin with the given name (identifier)
      #
      # @param [String] name The name of the plugin class to find
      #
      # @return [Class] The plugin class with the given name
      def named(name)
        Nanoc3::Plugin.find(self, name)
      end

    end

    # Returns the shared {PluginRegistry} instance, creating it if none exists
    # yet.
    #
    # @return [Nanoc3::PluginRegistry] The shared plugin registry
    def self.instance
      @instance ||= self.new
    end

    # Creates a new plugin registry. This should usually not be necessary; it
    # is recommended to use the shared instance (obtained from
    # {Nanoc3::PluginRegistry.instance}).
    def initialize
      @map = {}
    end

    # Registers the given class as a plugin.
    #
    # @param [Class] superclass The superclass of the plugin. For example:
    # {Nanoc3::Filter}, {Nanoc3::Extra::VCS}.
    #
    # @param [Class, String] class_or_name The class to register. This can be
    # a string, in which case it will be automatically converted to a proper
    # class at lookup. For example: `Nanoc3::Filters::ERB`,
    # `"Nanoc3::Filters::Haml"`.
    #
    # @param [Symbol] identifiers One or more symbols identifying the class.
    # For example: `:haml`, :`erb`.
    #
    # @return [void]
    def register(superclass, class_or_name, *identifiers)
      @map[superclass] ||= {}

      identifiers.each do |identifier|
        @map[superclass][identifier.to_sym] = class_or_name
      end
    end

    # Finds the plugin that is a subclass of the given class and has the given
    # name.
    #
    # @param [Symbol] name The name of the plugin to return
    #
    # @return [Class, nil] The plugin with the given name
    def find(klass, name)
      # Initialize
      @map[klass] ||= {}

      # Lookup
      class_or_name = @map[klass][name.to_sym]

      # Get class
      if class_or_name.is_a?(String)
        class_or_name.scan(/\w+/).inject(klass) { |memo, part| memo.const_get(part) }
      else
        class_or_name
      end
    end

    # Returns a list of all plugins. The returned list of plugins is an array
    # with array elements in the following format:
    #
    #   { :class => ..., :superclass => ..., :identifiers => ... }
    #
    # @return [Array<Hash>] A list of all plugins in the format described
    def all
      plugins = []
      @map.each_pair do |superclass, submap|
        submap.each_pair do |identifier, klass|
          # Find existing plugin
          existing_plugin = plugins.find do |p|
            p[:class] == klass && p[:superclass] == superclass
          end

          if existing_plugin
            # Add identifier to existing plugin
            existing_plugin[:identifiers] << identifier
            existing_plugin[:identifiers] = existing_plugin[:identifiers].sort_by { |s| s.to_s }
          else
            # Create new plugin
            plugins << {
              :class       => klass,
              :superclass  => superclass,
              :identifiers => [ identifier ]
            }
          end
        end
      end

      plugins
    end

    # @deprecated Use {Nanoc3::PluginRegistry#find} instead
    def named(name)
      find(self, name)
    end

  end

  # @deprecated Use {Nanoc3::PluginRegistry.instace} instead
  Plugin = PluginRegistry.instance

end
