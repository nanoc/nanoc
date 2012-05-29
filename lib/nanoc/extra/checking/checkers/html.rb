# encoding: utf-8   

module ::Nanoc::Extra::Checking::Checkers

  class HTML < ::Nanoc::Extra::Checking::Checker

    identifier :html

    def run
      require 'w3c_validators'

      issues = []
      Dir[site.config[:output_dir] + '/**/*.{htm,html}'].each do |filename|
        results = ::W3CValidators::MarkupValidator.new.validate_file(filename)
        results.errors.each do |e|
          issues << "#{filename}: #{e}"
        end
      end
      issues
    end

  end

end

