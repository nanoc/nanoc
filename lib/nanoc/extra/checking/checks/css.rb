# encoding: utf-8

module ::Nanoc::Extra::Checking::Checks
  # @api private
  class CSS < ::Nanoc::Extra::Checking::Check
    identifier :css

    def run
      require 'w3c_validators'

      Dir[@config[:output_dir] + '/**/*.css'].each do |filename|
        results = ::W3CValidators::CSSValidator.new.validate_file(filename)
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
