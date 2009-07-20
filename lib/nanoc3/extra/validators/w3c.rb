# encoding: utf-8

module Nanoc3::Extra::Validators

  # Nanoc3::Extra::Validators::W3C is a validator that uses the W3C web
  # service to validate HTML and CSS files.
  class W3C

    def initialize(site, type)
      @site = site
      @type = type
    end

    def run
      # Load validator
      require 'w3c_validators'

      # Make sure config is loaded
      @site.load_data

      # Find all files
      files = extensions.map { |extension| Dir["#{@site.config[:output_dir]}/**/*.#{extension}"] }.flatten

      # Validate each file
      files.each do |file|
        validation_started(file)
        results = validator.validate_file(file)
        validation_ended(file, results.errors)
      end
    end

  private

    def extensions
      case @type
      when :html
        [ 'html', 'htm' ]
      when :css
        [ 'css' ]
      end
    end

    def validator_class
      case @type
      when :html
        ::W3CValidators::MarkupValidator
      when :css
        ::W3CValidators::CSSValidator
      end
    end

    def validator
      @validator ||= validator_class.new
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
