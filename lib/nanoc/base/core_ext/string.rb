# encoding: utf-8

# @api private
module Nanoc::StringExtensions
  # Transforms string into an actual identifier
  #
  # @return [String] The identifier generated from the receiver
  def cleaned_identifier
    "/#{self}/".gsub(/^\/+|\/+$/, '/')
  end

  # Calculates the checksum for this string. Any change to this string will
  # result in a different checksum.
  #
  # @return [String] The checksum for this string
  #
  # @api private
  def checksum
    Nanoc::Int::Checksummer.calc(self)
  end
end

class String
  include Nanoc::StringExtensions
end
