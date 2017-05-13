# frozen_string_literal: true

module ::Nanoc::Checking::Checks
  # @api private
  class W3CValidator < ::Nanoc::Checking::Check
    def run
      require 'w3c_validators'
      require 'resolv-replace'

      Dir[@config[:output_dir] + '/**/*.' + extension].each do |filename|
        results = validator_class.new.validate_file(filename)
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

    def extension
      raise NotImplementedError
    end

    def validator_class
      raise NotImplementedError
    end
  end
end
