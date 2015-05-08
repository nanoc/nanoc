# encoding: utf-8

# @api private
module Nanoc::PathnameExtensions
  # Calculates the checksum for the file referenced to by this pathname. Any
  # change to the file contents will result in a different checksum.
  #
  # @return [String] The checksum for this file
  #
  # @api private
  def checksum
    Nanoc::Int::Checksummer.calc(self)
  end
end

class Pathname
  include Nanoc::PathnameExtensions
end
