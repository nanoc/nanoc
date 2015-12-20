module ::Nanoc::Extra::Checking::Checks
  # @api private
  class CSS < ::Nanoc::Extra::Checking::Checks::W3CValidator
    identifier :css

    def extension
      'css'
    end

    def validator_class
      ::W3CValidators::CSSValidator
    end
  end
end
