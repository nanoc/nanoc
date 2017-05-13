# frozen_string_literal: true

module ::Nanoc::Checking::Checks
  # @api private
  class CSS < ::Nanoc::Checking::Checks::W3CValidator
    identifier :css

    def extension
      'css'
    end

    def validator_class
      ::W3CValidators::CSSValidator
    end
  end
end
