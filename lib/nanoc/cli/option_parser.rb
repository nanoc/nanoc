module Nanoc::CLI

  class OptionParser

    class IllegalOptionError < RuntimeError             ; end
    class OptionRequiresAnArgumentError < RuntimeError  ; end

    def self.parse(arguments_and_options, definitions)
      # Don't touch original argument
      unprocessed_arguments_and_options = arguments_and_options.dup

      # Initialize 
      arguments = []
      options   = {}

      # Determines whether we've passed the '--' marker or not
      no_more_options = false

      loop do
        # Get next item
        e = unprocessed_arguments_and_options.shift
        break if e.nil?

        # Handle end-of-options marker
        if e == '--'
          no_more_options = true
        # Handle incomplete options
        elsif e =~ /^--./ and !no_more_options
          # Get option key, and option value if included
          if e =~ /^--([^=]+)=(.+)$/
            option_key   = $1
            option_value = $2
          else
            option_key    = e[2..-1]
            option_value  = nil
          end

          # Find definition
          definition = definitions.find { |d| d[:long] == option_key }
          raise IllegalOptionError.new(option_key) if definition.nil?

          if definition[:argument] == :required
            # Get option value if necessary
            if option_value.nil?
              option_value = unprocessed_arguments_and_options.shift
              raise OptionRequiresAnArgumentError.new(option_key) if option_value.nil?
            end

            # Store option
            options[definition[:long].to_sym] = option_value
          else
            # Store option
            options[definition[:long].to_sym] = nil
          end
        # Handle -xyz options
        elsif e =~ /^-./ and !no_more_options
          # Get option keys
          option_keys = e[1..-1].scan(/./)

          # For each key
          option_keys.each do |option_key|
            # Find definition
            definition = definitions.find { |d| d[:short] == option_key }
            raise IllegalOptionError.new(option_key) if definition.nil?

            if option_keys.length > 1 and definition[:argument] == :required
              # This is a combined option and it requires an argument, so complain
              raise OptionRequiresAnArgumentError.new(option_key) if option_value.nil?
            elsif definition[:argument] == :required
              # Get option value
              option_value = unprocessed_arguments_and_options.shift
              raise OptionRequiresAnArgumentError.new(option_key) if option_value.nil?

              # Store option
              options[definition[:long].to_sym] = option_value
            else
              # Store option
              options[definition[:long].to_sym] = nil
            end
          end
        # Handle normal arguments
        else
          arguments << e
        end
      end

      { :options => options, :arguments => arguments }
    end

  end

end
