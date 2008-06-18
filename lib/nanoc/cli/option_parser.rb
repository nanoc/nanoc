module Nanoc::CLI

  # Nanoc::CLI::OptionParser is used for parsing commandline options.
  class OptionParser

    # Error that will be raised when an unknown option is encountered.
    class IllegalOptionError < RuntimeError ; end

    # Error that will be raised when an option without argument is
    # encountered.
    class OptionRequiresAnArgumentError < RuntimeError ; end

    # Parses the commandline arguments in +arguments_and_options+, using the
    # commandline option definitions in +definitions+.
    #
    # +arguments_and_options+ is an array of commandline arguments and
    # options. This will usually be +ARGV+.
    #
    # +definitions+ contains a list of hashes defining which options are
    # allowed and how they will be handled. Such a hash has three keys:
    #
    # :short:: The short name of the option, e.g. +a+. Do not include the '-'
    #          prefix.
    #
    # :long:: The long name of the option, e.g. +all+. Do not include the '--'
    #         prefix.
    #
    # :argument:: Whether this option's argument is required (:required) or
    #             forbidden (:forbidden).
    #
    # A sample array of definition hashes could look like this:
    #
    #     [
    #       { :short => 'a', :long => 'all',  :argument => :forbidden },
    #       { :short => 'p', :long => 'port', :argument => :required  },
    #     ]
    #
    # During parsing, two errors can be raised:
    #
    # IllegalOptionError:: An unrecognised option was encountered, i.e. an
    #                      option that is not present in the list of option
    #                      definitions.
    #
    # OptionRequiresAnArgumentError:: An option was found that did not have a
    #                                 value, even though this value was
    #                                 required.
    #
    # What will be returned, is a hash with two keys, :arguments and :options.
    # The :arguments value contains a list of arguments, and the :options
    # value contains a hash with key-value pairs for each option. Options
    # without values will have a +nil+ value instead.
    #
    # For example, the following commandline options (which should not be
    # passed as a string, but as an array of strings):
    #
    #     foo bar -xyz -a hiss --level 50 --father=ani -n luke squeak
    #
    # with the following option definitions:
    #
    #     [
    #       { :short => 'x', :long => 'xxx',    :argument => :forbidden },
    #       { :short => 'y', :long => 'yyy',    :argument => :forbidden },
    #       { :short => 'z', :long => 'zzz',    :argument => :forbidden },
    #       { :short => 'a', :long => 'all',    :argument => :forbidden },
    #       { :short => 'l', :long => 'level',  :argument => :required  },
    #       { :short => 'f', :long => 'father', :argument => :required  },
    #       { :short => 'n', :long => 'name',   :argument => :required  }
    #     ]
    #
    # will be translated into:
    #
    #     {
    #       :arguments => [ 'foo', 'bar', 'hiss', 'squeak' ],
    #       :options => {
    #         :xxx    => nil,
    #         :yyy    => nil,
    #         :zzz    => nil,
    #         :all    => nil,
    #         :level  => '50',
    #         :father => 'ani',
    #         :name   => 'luke'
    #       }
    #     }
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
