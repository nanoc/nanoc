# encoding: utf-8

module ::Nanoc::Extra::Checking::Checks
  class HTML < ::Nanoc::Extra::Checking::Check
    identifier :html

    def run
      require 'w3c_validators'

      Dir[site.config[:output_dir] + '/**/*.{htm,html}'].each do |filename|
        results = ::W3CValidators::MarkupValidator.new.validate_file(filename)
        lines = File.readlines(filename)
        results.errors.each do |e|
          line_num = e.line.to_i - 1
          line = lines[line_num]
          message = e.message.gsub(%r{\s+}, ' ').strip.sub(/\s+:$/, '')
          desc = "line #{line_num + 1}: #{message}: #{line}"
          add_issue(desc, subject: filename)
        end
      end
    end
  end
end
