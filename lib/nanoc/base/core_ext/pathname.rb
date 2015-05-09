# encoding: utf-8

# @api private
module Nanoc::PathnameExtensions
  # Calculates the checksum for the file referenced to by this pathname. Any
  # change to the file contents will result in a different checksum.
  #
  # @return [String] The checksum for this file
  #
  # @api private
  def __nanoc_checksum
    Nanoc::Int::Checksummer.calc(self)
  end
end

# @api private
class Pathname
  include Nanoc::PathnameExtensions
end
