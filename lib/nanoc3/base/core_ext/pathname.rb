# encoding: utf-8

module Nanoc3::PathnameExtensions

  # Calculates the checksum for the file referenced to by this pathname. Any
  # change to the file contents will result in a different checksum.
  #
  # @return [String] The checksum for this file
  #
  # @api private
  def checksum
    require 'digest'

    digest = Digest::SHA1.new
    File.open(self.to_s, 'r') do |io|
      until io.eof
        data = io.readpartial(2**10)
        digest.update(data)
      end
    end
    digest.hexdigest
  end

end

class Pathname
  include Nanoc3::PathnameExtensions
end
