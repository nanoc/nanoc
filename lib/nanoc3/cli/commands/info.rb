# encoding: utf-8

module Nanoc3::CLI::Commands

  class Info < Cri::Command

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
      'and VCSes. If the current directory contains a nanoc web site, ' +
      'the plugins defined in this site will be shown as well.'
    end

    def usage
      "nanoc3 info [options]"
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
      plugins_before = Nanoc3::Plugin.all
      @base.site
      @base.site.load_data if @base.site
      plugins_after  = Nanoc3::Plugin.all

      # Divide list of plugins into builtin and custom
      plugins_builtin = plugins_before
      plugins_custom  = plugins_after - plugins_before

      # Find max identifiers length
      plugin_with_longest_identifiers = plugins_after.inject do |longest, current|
        longest[:identifiers].join(', ').size > current[:identifiers].join(', ').size ? longest : current
      end
      max_identifiers_length = plugin_with_longest_identifiers[:identifiers].join(', ').size

      PLUGIN_CLASS_ORDER.each do |superclass|
        plugins_with_this_superclass = {
          :builtin => plugins_builtin.select { |p| p[:superclass] == superclass },
          :custom  => plugins_custom.select  { |p| p[:superclass] == superclass }
        }

        # Print kind
        kind = name_for_plugin_class(superclass)
        puts "#{kind}:"
        puts

        # Print plugins organised by subtype
        [ :builtin, :custom ].each do |type|
          # Find relevant plugins
          relevant_plugins = plugins_with_this_superclass[type]

          # Print type
          puts "  #{type}:"
          if relevant_plugins.empty?
            puts "    (none)"
            next
          end

          # Print plugins
          relevant_plugins.sort_by { |k| k[:identifiers].join(', ') }.each do |plugin|
            # Display
            puts sprintf(
              "    %-#{max_identifiers_length}s (%s)",
              plugin[:identifiers].join(', '),
              plugin[:class].to_s.sub(/^::/, '')
            )
          end
        end

        puts
      end
    end

  private

    PLUGIN_CLASS_ORDER = [
      Nanoc3::Filter,
      Nanoc3::Extra::VCS,
      Nanoc3::DataSource
    ]

    PLUGIN_CLASSES = {
      Nanoc3::Filter       => 'Filters',
      Nanoc3::DataSource   => 'Data Sources',
      Nanoc3::Extra::VCS   => 'VCSes'
    }

    def name_for_plugin_class(klass)
      PLUGIN_CLASSES[klass]
    end

  end

end
