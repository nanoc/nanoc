module Nanoc::Int
  # The class responsible for keeping track of all loaded plugins, such as
  # filters ({Nanoc::Filter}) and data sources ({Nanoc::DataSource}).
  #
  # @api private
  class PluginRegistry
    extend Nanoc::Int::Memoization

    include Nanoc::Int::ContractsSupport

    # A module that contains class methods for plugins. It provides functions
    # for setting identifiers, registering plugins and finding plugins. Plugin
    # classes should extend this module.
    module PluginMethods
      include Nanoc::Int::ContractsSupport

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
          registry = Nanoc::Int::PluginRegistry.instance
          registry.identifiers_of(registry.root_class_of(self), self)
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
      def identifier(identifier = nil)
        if identifier
          identifiers(identifier)
        else
          registry = Nanoc::Int::PluginRegistry.instance
          registry.identifiers_of(registry.root_class_of(self), self).first
        end
      end

      # Registers the given class as a plugin with the given identifier(s).
      contract Class, C::Args[Symbol] => C::Any
      def register(klass, *identifiers)
        registry = Nanoc::Int::PluginRegistry.instance
        root = registry.root_class_of(self)
        registry.register(root, klass, *identifiers)
      end

      contract C::None => C::HashOf[Symbol, Class]
      def all
        Nanoc::Int::PluginRegistry.instance.find_all(self)
      end

      # Returns the plugin with the given name (identifier)
      contract C::Or[String, Symbol] => C::Maybe[Class]
      def named(name)
        Nanoc::Int::PluginRegistry.instance.find(self, name)
      end
    end

    # Returns the shared {PluginRegistry} instance, creating it if none exists
    # yet.
    #
    # @return [Nanoc::Int::PluginRegistry] The shared plugin registry
    def self.instance
      @instance ||= new
    end

    # Creates a new plugin registry. This should usually not be necessary; it
    # is recommended to use the shared instance (obtained from
    # {Nanoc::Int::PluginRegistry.instance}).
    def initialize
      @identifiers_to_classes = {}
      @classes_to_identifiers = {}
    end

    # Registers the given class as a plugin.
    #
    # @param [Class] superclass The superclass of the plugin. For example:
    #   {Nanoc::Filter}.
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
    contract Class, Class, C::Args[Symbol] => C::Any
    def register(superclass, klass, *identifiers)
      @identifiers_to_classes[superclass] ||= {}
      @classes_to_identifiers[superclass] ||= {}

      identifiers.each do |identifier|
        @identifiers_to_classes[superclass][identifier.to_sym] = klass
        (@classes_to_identifiers[superclass][name_for_class(klass)] ||= []) << identifier.to_sym
      end
    end

    contract Class, Class => C::IterOf[Symbol]
    def identifiers_of(superclass, klass)
      (@classes_to_identifiers[superclass] || {})[name_for_class(klass)] || []
    end

    # Finds the plugin that is a subclass of the given class and has the given
    # name.
    contract Class, C::Or[String, Symbol] => C::Maybe[Class]
    def find(klass, name)
      @identifiers_to_classes[klass] ||= {}
      resolve(@identifiers_to_classes[klass][name.to_sym], klass)
    end

    # Returns all plugins of the given class.
    contract Class => C::HashOf[Symbol, Class]
    def find_all(klass)
      @identifiers_to_classes[klass] ||= {}
      res = {}
      @identifiers_to_classes[klass].each_pair { |k, v| res[k] = resolve(v, k) }
      res
    end

    contract Class => Class
    def root_class_of(subclass)
      root_class = subclass
      root_class = root_class.superclass while root_class.superclass.respond_to?(:register)
      root_class
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
            existing_plugin[:identifiers] = existing_plugin[:identifiers].sort_by(&:to_s)
          else
            # Create new plugin
            plugins << {
              class: klass,
              superclass: superclass,
              identifiers: [identifier],
            }
          end
        end
      end

      plugins
    end

    protected

    def resolve(class_or_name, _klass)
      if class_or_name.is_a?(String)
        Kernel.const_get(class_or_name)
      else
        class_or_name
      end
    end
    memoize :resolve

    def name_for_class(klass)
      klass.to_s.sub(/^(::)?/, '::')
    end
  end
end
