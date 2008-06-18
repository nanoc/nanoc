module Nanoc::CLI

  # Nanoc::CLI::Command represents a command that can be executed on the
  # commandline. It is an abstract superclass for all commands.
  class Command

    attr_accessor :base

    # Returns a string containing the name of thi command. Subclasses must
    # implement this method.
    def name
      raise NotImplementedError.new("Command subclasses should override #name")
    end

    # Returns an array of strings containing the aliases for this command.
    # Subclasses must implement this method.
    def aliases
      raise NotImplementedError.new("Command subclasses should override #aliases")
    end

    # Returns a string containing this command's short description, which
    # should not be longer than 50 characters. Subclasses must implement this
    # method.
    def short_desc
      raise NotImplementedError.new("Command subclasses should override #short_desc")
    end

    # Returns a string containing this command's complete description, which
    # should explain what this command does and how it works in detail.
    # Subclasses must implement this method.
    def long_desc
      raise NotImplementedError.new("Command subclasses should override #long_desc")
    end

    # Returns a string containing this command's usage. Subclasses must
    # implement this method.
    def usage
      raise NotImplementedError.new("Command subclasses should override #usage")
    end

    # Returns an array containing this command's option definitions. See the
    # documentation for Nanoc::CLI::OptionParser for details on what option
    # definitions look like. Subclasses may implement this method if the
    # command has options.
    def option_definitions
      []
    end

    # Executes the command. Subclasses must implement this method
    # (obviously... what's the point of a command that can't be run?).
    #
    # +options+:: A hash containing the parsed commandline options. For
    #             example, '--foo=bar' will be converted into { :foo => 'bar'
    #             }. See the Nanoc::CLI::OptionParser documentation for
    #             details.
    #
    # +arguments+:: An array of strings representing the commandline arguments
    #               given to this command.
    def run(options, arguments)
      raise NotImplementedError.new("Command subclasses should override #run")
    end

    # Returns the help text for this command.
    def help
      text = ''

      # Append usage
      text << usage + "\n"

      # Append aliases
      unless aliases.empty?
        text << "\n"
        text << "aliases: #{aliases.join(' ')}\n"
      end

      # Append short description
      text << "\n"
      text << short_desc + "\n"

      # Append long description
      text << "\n"
      text << long_desc.wrap_and_indent(78, 4) + "\n"

      # Append options
      unless option_definitions.empty?
        text << "\n"
        text << "options:\n"
        text << "\n"
        option_definitions.sort { |x,y| x[:long] <=> y[:long] }.each do |opt_def|
          text << sprintf("    -%1s --%-10s %s\n", opt_def[:short], opt_def[:long], opt_def[:desc])
        end
      end

      # Return text
      text
    end

    # Compares this command's name to the other given command's name.
    def <=>(other)
      self.name <=> other.name
    end

  end

end
