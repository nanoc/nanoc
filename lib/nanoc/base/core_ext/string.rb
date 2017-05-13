# frozen_string_literal: true

# @api private
module Nanoc::StringExtensions
  # Transforms string into an actual identifier
  #
  # @return [String] The identifier generated from the receiver
  def __nanoc_cleaned_identifier
    "/#{self}/".gsub(/^\/+|\/+$/, '/')
  end
end

# @api private
class String
  include Nanoc::StringExtensions
end
