# frozen_string_literal: true

module ::Nanoc::Checking::Checks
  # @api private
  class HTML < ::Nanoc::Checking::Checks::W3CValidator
    identifier :html

    def extension
      '{htm,html}'
    end

    def validator_class
      ::W3CValidators::NuValidator
    end
  end
end
