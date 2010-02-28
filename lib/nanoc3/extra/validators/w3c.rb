# encoding: utf-8

module Nanoc3::Extra::Validators

  # A validator that uses the W3C web service to validate HTML and CSS files.
  class W3C

    # @param [String] dir The directory that will be searched for HTML and/or
    # CSS files to validate
    #
    # @param [Array<Symbol>] types A list of types to check. Allowed types are
    # `:html` and `:css`.
    def initialize(dir, types)
      @dir   = dir
      @types = types
    end

    # Starts the validator. The results will be printed to stdout.
    #
    # @return [void]
    def run
      # Load validator
      require 'w3c_validators'

      # Find all files
      filenames = []
      extensions = types_to_extensions(@types)
      extensions.each { |extension| filenames.concat(Dir[@dir + '/**/*.' + extension]) }

      # Validate each file
      filenames.each do |filename|
        validation_started(filename)

        extension = File.extname(filename)[1..-1]
        results = validator_for(extension).validate_file(filename)

        validation_ended(filename, results.errors)
      end
    end

  private

    # Returns all extensions for the given types
    def types_to_extensions(types)
      extensions = []
      types.each { |type| extensions.concat(type_to_extensions(type)) }
      extensions
    end

    # Returns all extensions for the given type
    def type_to_extensions(type)
      case type
        when :html
          [ 'html', 'htm' ]
        when :css
          [ 'css' ]
        else
          raise RuntimeError, "unknown type: #{type}"
      end
    end

    # Returns the validator class for the given extension
    def validator_class_for(extension)
      case extension
      when 'html', 'htm'
        ::W3CValidators::MarkupValidator
      when 'css'
        ::W3CValidators::CSSValidator
      else
        raise RuntimeError, "unknown extension: #{extension}"
      end
    end

    # Returns the validator for the given extension
    def validator_for(extension)
      @validators ||= {}
      @validators[extension] ||= validator_class_for(extension).new
    end

    def validation_started(file)
      $stdout.print "Validating #{file}... "
      $stdout.flush
    end

    def validation_ended(file, errors)
      $stdout.puts(errors.empty? ? "valid" : "INVALID")

      errors.each do |err|
        puts "    #{err}"
      end
    end

  end

end
