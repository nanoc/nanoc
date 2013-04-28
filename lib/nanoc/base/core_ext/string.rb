# encoding: utf-8

module Nanoc::StringExtensions

  # TODO remove me
  def stem
    extension = File.extname(self)
    if extension.empty?
      self
    else
      self[0..-(1+extension.length)].stem
    end
  end

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
