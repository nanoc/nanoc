# encoding: utf-8

module Nanoc::StringExtensions

  # Calculates the checksum for this string. Any change to this string will
  # result in a different checksum.
  #
  # @return [String] The checksum for this string
  #
  # @api private
  def checksum
    digest = Digest::SHA1.new
    digest.update(self)
    digest.hexdigest
  end

end

class String
  include Nanoc::StringExtensions
end
