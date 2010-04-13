# encoding: utf-8

module Nanoc3

  # Responsible for creating checksums of files. Such checksums are used to
  # determine whether files have changed between compilations.
  class Checksummer

    # Returns a checksum for the specified file. Multiple invocations of this
    # method with the same filename argument will yield the same result.
    #
    # The returned checksum has the property that for two given files with
    # different content, the returned checksum will be different with a very
    # high probability. In practice, this boils down to using a secure
    # cryptographic hash function, such as SHA-1.
    #
    # The format of the resulting checksum should not be relied upon. In
    # future versions of nanoc, this function may use a different method for
    # generating checksums.
    #
    # @param [String] filename The name of the file for which the checksum
    #   should be calculated
    #
    # @return [String] The checksum for the given files
    def self.checksum_for(filename)
      require 'digest'

      digest = Digest::SHA1.new
      File.open(filename, 'r') do |io|
        until io.eof
          data = io.readpartial(2**10)
          digest.update(data)
        end
      end
      digest.hexdigest
    end

  end

end
