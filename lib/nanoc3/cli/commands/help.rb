# encoding: utf-8

module Nanoc3::CLI::Commands

  class Help < Cri::Command

    def name
      'help'
    end

    def aliases
      []
    end

    def short_desc
      'show help for a command'
    end

    def long_desc
      'Show help for the given command, or show general help. When no ' +
      'command is given, a list of available commands is displayed, as ' +
      'well as a list of global commandline options. When a command is ' +
      'given, a command description as well as command-specific ' +
      'commandline options are shown.'
    end

    def usage
      "nanoc3 help [options] [command]"
    end

    def run(options, arguments)
      # Check arguments
      if arguments.size > 1
        $stderr.puts "usage: #{usage}"
        exit 1
      end

      if arguments.length == 0
        # Build help text
        text = ''

        # Add title
        text << "nanoc, a static site compiler written in Ruby.\n"

        # Add available commands
        text << "\n"
        text << "Available commands:\n"
        text << "\n"
        @base.commands.sort.each do |command|
          text << sprintf("    %-20s %s\n", command.name, command.short_desc)
        end

        # Add global options
        text << "\n"
        text << "Global options:\n"
        text << "\n"
        @base.global_option_definitions.sort { |x,y| x[:long] <=> y[:long] }.each do |opt_def|
          text << sprintf("    -%1s --%-15s %s\n", opt_def[:short], opt_def[:long], opt_def[:desc])
        end

        # Display text
        puts text
      elsif arguments.length == 1
        command = @base.command_named(arguments[0])
        puts command.help
      end
    end

  end

end
