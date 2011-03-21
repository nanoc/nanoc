# encoding: utf-8

module Nanoc3

  # Stores checksums for objects in order to be able to detect whether a file
  # has changed since the last site compilation.
  #
  # Old checksums are checksums that were in effect during the previous site
  # compilation. New checksums are checksums that are in effect right now. If
  # an old checksum differs from a new checksum, the corresponding object was
  # modified and will need to be recompiled (along with the objects that
  # depend on that object).
  #
  # @api private
  class ChecksumStore < ::Nanoc3::Store
    CHECKSUM_FILE = 'checksum'

    # @param [Nanoc3::Site] site The site where this checksum store belongs to
    def initialize(site)
      super("#{site.config[:tmp_dir]}/#{CHECKSUM_FILE}", 1)

      @site = site
      @new_checksums = {}
      @old_checksums = {}
    end

    # Returns the old checksum for the given object. The object must respond
    # to `#reference` (for example, {Nanoc3::Item#reference},
    # {Nanoc3::Layout#reference}, {Nanoc3::CodeSnippet#reference}, …).
    #
    # @param [#reference] obj The object for which to fetch the old checksum
    #
    # @return [String] The old checksum for the given object
    def old_checksum_for(obj)
      @old_checksums[obj.reference]
    end

    # Returns the new checksum for the given object. The object must respond
    # to `#reference` (for example, {Nanoc3::Item#reference},
    # {Nanoc3::Layout#reference}, {Nanoc3::CodeSnippet#reference}, …).
    #
    # @param [#reference] obj The object for which to calculate the new
    #   checksum
    #
    # @return [String] The new checksum for the given object
    def new_checksum_for(obj)
      @new_checksums[obj.reference] ||= begin
        checksum_parts = []

        # Calculate content checksum
        checksum_parts << if obj.respond_to?(:binary?) && obj.binary?
          Nanoc3::Checksummer.checksum_for_file(obj.raw_filename)
        elsif obj.respond_to?(:raw_content)
          Nanoc3::Checksummer.checksum_for_string(obj.raw_content)
        elsif obj.respond_to?(:data)
          Nanoc3::Checksummer.checksum_for_string(obj.data)
        else
          raise RuntimeError, "Couldn’t figure out how to calculate the " \
            "content checksum for #{obj.inspect} (tried #raw_filename, " \
            "#raw_content and #data but none of these worked)"
        end

        # Calculate attributes checksum
        if obj.respond_to?(:attributes)
          attributes = obj.attributes.dup
          attributes.delete(:file)
          checksum_parts << Nanoc3::Checksummer.checksum_for_hash(attributes)
        end

        # Done
        checksum_parts.join('-')
      end
    end

    # Calculates the checksums for all objects in the site. This method should
    # be used to make the checksum store remember the new checksums for all
    # given objects; it is probably necessary to call this method before
    # calling {#store}, to make sure that all new checksums are calculated. It
    # is not necessary to call this method in order to use
    # {#new_checksum_for}.
    #
    # @return [void]
    def calculate_all_checksums
      @site.compiler.objects.each { |obj| new_checksum_for(obj) }
    end

    # @param [#reference] obj
    #
    # @return [Boolean] false if either the new or the old checksum for the
    #   given object is not available, true if both checksums are available
    def checksums_available?(obj)
      !!old_checksum_for(obj) && !!new_checksum_for(obj)
    end

    # @param [#reference] obj
    #
    # @return [Boolean] false if the old and new checksums for the given
    #   object differ, true if they are identical
    def checksums_identical?(obj)
      old_checksum_for(obj) == new_checksum_for(obj)
    end

    # @param [#reference] obj
    #
    # @return [Boolean] true if the old and new checksums for the given object
    #   are available and identical, false otherwise
    def object_modified?(obj)
      !checksums_available?(obj) || !checksums_identical?(obj)
    end

    # @see Nanoc3::Store#store
    def store
      calculate_all_checksums
      super
    end

    # Undoes the effects of {#load}. Used when {#load} raises an exception.
    #
    # @api private
    def unload
      @new_checksums = {}
      @old_checksums = {}
    end

  protected

    def data
      @new_checksums
    end

    def data=(new_data)
      @old_checksums = new_data
    end

  end

end
