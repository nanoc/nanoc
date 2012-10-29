# encoding: utf-8

module Nanoc

  # The class responsible for keeping track of all loaded plugins, such as
  # filters ({Nanoc::Filter}), data sources ({Nanoc::DataSource}) and VCSes
  # ({Nanoc::Extra::VCS}).
  class PluginRegistry

    extend Nanoc::Memoization

    # A module that contains class methods for plugins. It provides functions
    # for setting identifiers, registering plugins and finding plugins. Plugin
    # classes should extend this module.
    module PluginMethods

      # @overload identifiers(*identifiers)
      #
      #   Sets the identifiers for this plugin.
      #
      #   @param [Array<Symbol>] identifiers A list of identifiers to assign to
      #     this plugin.
      #
      #   @return [void]
      #
      # @overload identifiers
      #
      #   @return [Array<Symbol>] The identifiers for this plugin
      def identifiers(*identifiers)
        if identifiers.empty?
          Nanoc::PluginRegistry.instance.identifiers_of(self.superclass, self)
        else
          register(self, *identifiers)
        end
      end

      # @overload identifier(identifier)
      #
      #   Sets the identifier for this plugin.
      #
      #   @param [Symbol] identifier An identifier to assign to this plugin.
      #
      #   @return [void]
      #
      # @overload identifier
      #
      #   @return [Symbol] The first identifier for this plugin
      def identifier(identifier=nil)
        if identifier
          self.identifiers(identifier)
        else
          Nanoc::PluginRegistry.instance.identifiers_of(self.superclass, self).first
        end
      end

      # Registers the given class as a plugin with the given identifier.
      #
      # @param [Class, String] class_or_name The class to register, or a
      #   string containing the class name to register.
      #
      # @param [Array<Symbol>] identifiers A list of identifiers to assign to
      #   this plugin.
      #
      # @return [void]
      def register(class_or_name, *identifiers)
        # Find plugin class
        klass = self
        klass = klass.superclass while klass.superclass.respond_to?(:register)

        # Register
        registry = Nanoc::PluginRegistry.instance
        registry.register(klass, class_or_name, *identifiers)
      end

      # @return [Hash<Symbol, Class>] All plugins of this type, with keys
      #   being the identifiers and values the plugin classes
      def all
        Nanoc::Plugin.find_all(self)
      end

      # Returns the plugin with the given name (identifier)
      #
      # @param [String] name The name of the plugin class to find
      #
      # @return [Class] The plugin class with the given name
      def named(name)
        Nanoc::Plugin.find(self, name)
      end

    end

    # Returns the shared {PluginRegistry} instance, creating it if none exists
    # yet.
    #
    # @return [Nanoc::PluginRegistry] The shared plugin registry
    def self.instance
      @instance ||= self.new
    end

    # Creates a new plugin registry. This should usually not be necessary; it
    # is recommended to use the shared instance (obtained from
    # {Nanoc::PluginRegistry.instance}).
    def initialize
      @identifiers_to_classes = {}
      @classes_to_identifiers = {}
    end

    # Registers the given class as a plugin.
    #
    # @param [Class] superclass The superclass of the plugin. For example:
    #   {Nanoc::Filter}, {Nanoc::Extra::VCS}.
    #
    # @param [Class, String] class_or_name The class to register. This can be
    #   a string, in which case it will be automatically converted to a proper
    #   class at lookup. For example: `Nanoc::Filters::ERB`,
    #   `"Nanoc::Filters::Haml"`.
    #
    # @param [Symbol] identifiers One or more symbols identifying the class.
    #   For example: `:haml`, :`erb`.
    #
    # @return [void]
    def register(superclass, class_or_name, *identifiers)
      @identifiers_to_classes[superclass] ||= {}
      @classes_to_identifiers[superclass] ||= {}

      identifiers.each do |identifier|
        @identifiers_to_classes[superclass][identifier.to_sym] = class_or_name
        (@classes_to_identifiers[superclass][name_for_class(class_or_name)] ||= []) << identifier.to_sym
      end
    end

    # @param [Class] superclass The superclass of the plugin. For example:
    #   {Nanoc::Filter}, {Nanoc::Extra::VCS}.
    #
    # @param [Class, String] class_or_name The class to get the identifiers for.
    #   This can also be a string containing the name of the class.
    #
    # @return [Array<Symbol>] An array of identifiers for the given class
    def identifiers_of(superclass, klass)
      (@classes_to_identifiers[superclass] || {})[name_for_class(klass)] || []
    end

    # Finds the plugin that is a subclass of the given class and has the given
    # name.
    #
    # @param [Class] klass The class of the plugin to return
    #
    # @param [Symbol] name The name of the plugin to return
    #
    # @return [Class, nil] The plugin with the given name
    def find(klass, name)
      @identifiers_to_classes[klass] ||= {}
      resolve(@identifiers_to_classes[klass][name.to_sym], klass)
    end

    # Returns all plugins of the given class.
    #
    # @param [Class] klass The class of the plugin to return
    #
    # @return [Enumerable<Class>] A collection of class plugins
    def find_all(klass)
      @identifiers_to_classes[klass] ||= {}
      res = {}
      @identifiers_to_classes[klass].each_pair { |k,v| res[k] = resolve(v, k) }
      res
    end

    # Returns a list of all plugins. The returned list of plugins is an array
    # with array elements in the following format:
    #
    #   { :class => ..., :superclass => ..., :identifiers => ... }
    #
    # @return [Array<Hash>] A list of all plugins in the format described
    def all
      plugins = []
      @identifiers_to_classes.each_pair do |superclass, submap|
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

    # @deprecated Use {Nanoc::PluginRegistry#find} instead
    def named(name)
      find(self, name)
    end

  protected

    def resolve(class_or_name, klass)
      if class_or_name.is_a?(String)
        class_or_name.scan(/\w+/).inject(Kernel) do |memo, part|
          memo.const_get(part)
        end
      else
        class_or_name
      end
    end
    memoize :resolve

    def name_for_class(klass)
      klass.to_s.sub(/^(::)?/, '::')
    end

  end

  # @deprecated Use {Nanoc::PluginRegistry.instance} instead
  Plugin = PluginRegistry.instance

end
