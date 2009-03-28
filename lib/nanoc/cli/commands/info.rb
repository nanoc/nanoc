module Nanoc::CLI

  class InfoCommand < Cri::Command # :nodoc:

    def name
      'info'
    end

    def aliases
      []
    end

    def short_desc
      'show info about available plugins'
    end

    def long_desc
      'Show a list of available plugins, including filters, data sources ' +
      'and routers. If the current directory contains a nanoc web site, ' +
      'the plugins defined in this site will be shown as well.'
    end

    def usage
      "nanoc info"
    end

    def option_definitions
      []
    end

    def run(options, arguments)
      # Check arguments
      if arguments.size != 0
        $stderr.puts "usage: #{usage}"
        exit 1
      end

      # Get list of plugins (before and after)
      plugins_before  = find_all_plugins
      @base.site
      plugins_after   = find_all_plugins

      # Get structured list of plugins
      plugins = {}
      plugin_classes.each do |klass|
        plugins[klass] = {
          :builtin  => plugins_before[klass],
          :custom   => plugins_after[klass] - plugins_before[klass]
        }
      end

      # Find longest name
      max_length = plugins.values.map { |k| k.values }.flatten.map { |k| k.identifiers.join(', ').length }.max + 2

      PLUGIN_CLASS_ORDER.each do |superclass|
        structured_plugins = plugins[superclass]

        # Print kind
        kind = name_for_plugin_class(superclass)
        puts "#{kind}:"
        puts

        # Print plugins organised by subtype
        [ :builtin, :custom ].each do |type|
          # Find relevant plugins
          subclasses = structured_plugins[type]

          # Print type
          puts "  #{type}:"
          if subclasses.empty?
            puts "    (none)"
            next
          end

          # Print plugins
          subclasses.sort_by { |k| k.identifier.to_s }.each do |klass|
            # Get data
            is_custom   = !plugins_before[superclass].include?(klass)
            klass_name  = klass.to_s
            klass_id    = klass.identifiers.join(', ')

            # Display
            puts sprintf("    %-#{max_length}s (%s)", klass_id, klass_name)
          end
        end

        puts
      end
    end

  private

    PLUGIN_CLASS_ORDER = [
      Nanoc::Filter,
      Nanoc::BinaryFilter,
      Nanoc::Router,
      Nanoc::Extra::VCS,
      Nanoc::DataSource
    ]

    PLUGIN_CLASSES = {
      Nanoc::BinaryFilter => 'Binary Filters',
      Nanoc::Filter       => 'Filters',
      Nanoc::DataSource   => 'Data Sources',
      Nanoc::Router       => 'Routers',
      Nanoc::Extra::VCS   => 'VCSes'
    }

    def find_all_plugins
      plugin_classes.inject({}) do |memo, klass|
        memo.merge(klass => Nanoc::Plugin::MAP[klass].values.uniq)
      end
    end

    def plugin_classes
      PLUGIN_CLASSES.keys
    end

    def name_for_plugin_class(klass)
      PLUGIN_CLASSES[klass]
    end

  end

end
