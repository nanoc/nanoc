# frozen_string_literal: true

module Nanoc
  module Core
    module CoreExt
      module StringExtensions
        # Transforms string into an actual identifier
        #
        # @return [String] The identifier generated from the receiver
        def __nanoc_cleaned_identifier
          "/#{self}/".gsub(/^\/+|\/+$/, '/')
        end
      end
    end
  end
end

class String
  include Nanoc::Core::CoreExt::StringExtensions
end
