# encoding: utf-8

module Nanoc3

  # Responsible for creating checksums of files. Such checksums are used to
  # determine whether files have changed between compilations.
  #
  # Identical content will always result in the same checksum. Multiple
  # invocations of the checksum creation methods with the same content or
  # filename will yield the same result.
  #
  # The returned checksum has the property that for two given files with
  # different content, the returned checksum will be different with a very
  # high probability. In practice, this boils down to using a secure
  # cryptographic hash function, such as SHA-1.
  #
  # The format of the resulting checksum should not be relied upon. In future
  # versions of nanoc, this function may use a different method for generating
  # checksums.
  #
  # @private
  class Checksummer

    # Returns a checksum for the specified file.
    #
    # @param [String] filename The name of the file for which the checksum
    #   should be calculated
    #
    # @return [String] The checksum for the given file
    def self.checksum_for_file(filename)
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

    # Returns a checksum for the specified string. 
    #
    # @param [String] string The string for which the checksum should be
    #   calculated
    #
    # @return [String] The checksum for the given string
    def self.checksum_for_string(string)
      require 'digest'

      digest = Digest::SHA1.new
      digest.update(string)
      digest.hexdigest
    end

    # Returns a checksum for the specified hash. 
    #
    # @param [Hash] hash The hash for which the checksum should be calculated.
    #
    # @return [String] The checksum for the given hash
    def self.checksum_for_hash(hash)
      self.checksum_for_string(YAML.dump(hash))
    end

  end

end
