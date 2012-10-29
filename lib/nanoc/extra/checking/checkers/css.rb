# encoding: utf-8   

module ::Nanoc::Extra::Checking::Checkers

  class CSS < ::Nanoc::Extra::Checking::Checker

    identifier :css

    def run
      require 'w3c_validators'

      Dir[site.config[:output_dir] + '/**/*.css'].each do |filename|
        results = ::W3CValidators::CSSValidator.new.validate_file(filename)
        results.errors.each do |e|
          desc = e.message.gsub(%r{\s+}, ' ').strip
          self.add_issue(desc, :subject => filename)
        end
      end
    end

  end

end
