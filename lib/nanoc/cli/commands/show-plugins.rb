summary 'show all available plugins'
aliases :info
usage 'show-plugins [options]'
description <<-EOS
Show a list of available plugins, including filters and data sources.
If the current directory contains a Nanoc web site, the plugins defined in this site will be shown as well.
EOS

module Nanoc::CLI::Commands
  class ShowPlugins < ::Nanoc::CLI::CommandRunner
    def run
      # Check arguments
      if arguments.any?
        raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
      end

      # Get list of plugins (before and after)
      plugins_before = PLUGIN_CLASSES.keys.each_with_object({}) { |c, acc| acc[c] = c.all }
      site.code_snippets if site
      plugins_after = PLUGIN_CLASSES.keys.each_with_object({}) { |c, acc| acc[c] = c.all }

      # Divide list of plugins into builtin and custom
      plugins_builtin = plugins_before
      plugins_custom  = plugins_after.each_with_object({}) do |(superclass, klasses), acc|
        acc[superclass] = klasses - plugins_before[superclass]
      end

      # Find max identifiers length
      all_identifiers = plugins_after.values.flatten.map(&:identifiers)
      max_identifiers_length = all_identifiers.map(&:to_s).map(&:size).max

      PLUGIN_CLASS_ORDER.each do |superclass|
        plugins_with_this_superclass = {
          builtin: plugins_builtin.fetch(superclass, []),
          custom: plugins_custom.fetch(superclass, []),
        }

        # Print kind
        kind = name_for_plugin_class(superclass)
        puts "#{kind}:"
        puts

        # Print plugins organised by subtype
        %i[builtin custom].each do |type|
          # Find relevant plugins
          relevant_plugins = plugins_with_this_superclass[type]

          # Print type
          puts "  #{type}:"
          if relevant_plugins.empty?
            puts '    (none)'
            next
          end

          # Print plugins
          relevant_plugins.sort_by { |k| k.identifiers.join(', ') }.each do |plugin|
            # Display
            puts format(
              "    %-#{max_identifiers_length}s (%s)",
              plugin.identifiers.join(', '),
              plugin.to_s.sub(/^::/, ''),
            )
          end
        end

        puts
      end
    end

    private

    PLUGIN_CLASS_ORDER = [
      Nanoc::Filter,
      Nanoc::DataSource,
      Nanoc::Deploying::Deployer,
    ].freeze

    PLUGIN_CLASSES = {
      Nanoc::Filter          => 'Filters',
      Nanoc::DataSource      => 'Data Sources',
      Nanoc::Deploying::Deployer => 'Deployers',
    }.freeze

    def name_for_plugin_class(klass)
      PLUGIN_CLASSES[klass]
    end
  end
end

runner Nanoc::CLI::Commands::ShowPlugins
