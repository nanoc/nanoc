# frozen_string_literal: true

module Nanoc
  module Checking
    module Checks
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
  end
end
