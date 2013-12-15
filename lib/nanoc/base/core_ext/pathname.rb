# encoding: utf-8

module Nanoc::PathnameExtensions

  # Calculates the checksum for the file referenced to by this pathname. Any
  # change to the file contents will result in a different checksum.
  #
  # @return [String] The checksum for this file
  #
  # @api private
  def checksum
    stat = File.stat(to_s)
    stat.size.to_s + '-' + stat.mtime.to_s
  end

end

class Pathname
  include Nanoc::PathnameExtensions
end
