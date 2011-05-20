# encoding: utf-8

module Nanoc3

  # Used for calculating checksums of items, layouts and code snippets.
  #
  # @api private
  class ChecksumCalculator

    extend Nanoc3::Memoization

    # Calculates the checksum for the given object. This method is suitable
    # for items, layouts and code snippets.
    #
    # @param obj The object for which to calculate the checksum
    #
    # @return [String] The checksum for the given object
    def [](obj)
      checksum_parts = []

      # Calculate content checksum
      checksum_parts << if obj.respond_to?(:binary?) && obj.binary?
        Pathname.new(obj.raw_filename).checksum
      elsif obj.respond_to?(:raw_content)
        obj.raw_content.checksum
      elsif obj.respond_to?(:data)
        obj.data.checksum
      else
        raise RuntimeError, "Couldn’t figure out how to calculate the " \
          "content checksum for #{obj.inspect} (tried #raw_filename, " \
          "#raw_content and #data but none of these worked)"
      end

      # Calculate attributes checksum
      if obj.respond_to?(:attributes)
        attributes = obj.attributes.dup
        attributes.delete(:file)
        checksum_parts << attributes.checksum
      end

      # Done
      checksum_parts.join('-')
    end
    memoize :[]

  end

end
