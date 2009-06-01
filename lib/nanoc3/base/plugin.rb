# encoding: utf-8

module Nanoc3

  # Nanoc3::Plugin is the superclass for all plugins, such as filters
  # (Nanoc3::Filter), routers (Nanoc3::Router), data sources (Nanoc3::DataSource)
  # and VCSes (Nanoc3::Extra::VCS). Each plugin has one or more unique
  # identifiers, and several methods in this class provides functionality for
  # finding plugins with given identifiers.
  class Plugin

    MAP = {}

    class << self

      # Registers the given class as a plugin.
      #
      # +superclass+:: The superclass of the plugin. For example:
      #                Nanoc::Filter, Nanoc::Router.
      #
      # +class_or_name+:: The class to register. This can be a string, in
      #                   which case it will be automatically converted to a
      #                   proper class at lookup. For example:
      #                   'Nanoc::Filters::ERB', Nanoc::Filters::Haml.
      #
      # +identifiers+:: One or more symbols identifying the class. For
      #                 example: :haml, :erb.
      def register(superclass, class_or_name, *identifiers)
        MAP[superclass] ||= {}

        identifiers.each do |identifier|
          MAP[superclass][identifier.to_sym] = class_or_name
        end
      end

      # Returns the the plugin with the given name. Only subclasses of this
      # class will be searched. For example, calling this method on
      # Nanoc3::Filter will cause only Nanoc3::Filter subclasses to be searched.
      def named(name)
        # Initialize
        MAP[self] ||= {}

        # Lookup
        class_or_name = MAP[self][name.to_sym]

        # Get class
        if class_or_name.is_a?(String)
          class_or_name.scan(/\w+/).inject(self) { |memo, part| memo.const_get(part) }
        else
          class_or_name
        end
      end

      # Returns a list of all plugins in the following format:
      #
      #   { :class => ..., :superclass => ..., :identifiers => ... }
      def all
        plugins = []
        MAP.each_pair do |superclass, submap|
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

    end

  end

end
