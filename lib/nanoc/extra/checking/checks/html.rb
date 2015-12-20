module ::Nanoc::Extra::Checking::Checks
  # @api private
  class HTML < ::Nanoc::Extra::Checking::Checks::W3CValidator
    identifier :html

    def extension
      '{htm,html}'
    end

    def validator_class
      ::W3CValidators::MarkupValidator
    end
  end
end
