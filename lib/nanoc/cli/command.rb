module Nanoc::CLI

  # TODO document
  class Command

    attr_accessor :base

    # TODO document
    def name
      raise NotImplementedError.new("Command subclasses should override #name")
    end

    # TODO document
    def aliases
      raise NotImplementedError.new("Command subclasses should override #aliases")
    end

    # TODO document
    def short_desc
      raise NotImplementedError.new("Command subclasses should override #short_desc")
    end

    # TODO document
    def long_desc
      raise NotImplementedError.new("Command subclasses should override #long_desc")
    end

    # TODO document
    def usage
      raise NotImplementedError.new("Command subclasses should override #usage")
    end

    # TODO document
    def option_definitions
      []
    end

    # TODO document
    def run(options, arguments)
      raise NotImplementedError.new("Command subclasses should override #run")
    end

    # TODO document
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

    # TODO document
    def <=>(other)
      self.name <=> other.name
    end

  end

end
