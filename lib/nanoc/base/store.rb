# encoding: utf-8

module Nanoc

  # An abstract superclass for classes that need to store data to the
  # filesystem, such as checksums, cached compiled content and dependency
  # graphs.
  #
  # Each store has a version number. When attempting to load data from a store
  # that has an incompatible version number, no data will be loaded, but
  # {#version_mismatch_detected} will be called.
  #
  # @abstract Subclasses must implement {#data} and {#data=}, and may
  #   implement {#no_data_found} and {#version_mismatch_detected}.
  #
  # @api private
  class Store

    # @return [String] The name of the file where data will be loaded from and
    #   stored to.
    attr_reader :filename

    # @return [Numeric] The version number corresponding to the file format
    #   the data is in. When the file format changes, the version number
    #   should be incremented.
    attr_reader :version

    # Creates a new store for the given filename.
    #
    # @param [String] filename The name of the file where data will be loaded
    #   from and stored to.
    #
    # @param [Numeric] version The version number corresponding to the file
    #   format the data is in. When the file format changes, the version
    #   number should be incremented.
    def initialize(filename, version)
      @filename = filename
      @version  = version
    end

    # @group Loading and storing data

    # @return The data that should be written to the disk
    #
    # @abstract This method must be implemented by the subclass.
    def data
      raise NotImplementedError.new("Nanoc::Store subclasses must implement #data and #data=")
    end

    # @param new_data The data that has been loaded from the disk
    #
    # @abstract This method must be implemented by the subclass.
    #
    # @return [void]
    def data=(new_data)
      raise NotImplementedError.new("Nanoc::Store subclasses must implement #data and #data=")
    end

    # Loads the data from the filesystem into memory. This method will set the
    #   loaded data using the {#data=} method.
    #
    # @return [void]
    def load
      # Don’t load twice
      if @loaded
        return
      end

      # Check file existance
      if !File.file?(self.filename)
        no_data_found
        @loaded = true
        return
      end

      pstore.transaction do
        # Check version
        if pstore[:version] != self.version
          version_mismatch_detected
          @loaded = true
          return
        end

        # Load
        self.data = pstore[:data]
        @loaded = true
      end
    end

    # Undoes the effects of {#load}. Used when {#load} raises an exception.
    #
    # @api private
    def unload
    end

    # Stores the data contained in memory to the filesystem. This method will
    #   use the {#data} method to fetch the data that should be written.
    #
    # @return [void]
    def store
      FileUtils.mkdir_p(File.dirname(self.filename))

      pstore.transaction do
        pstore[:data]    = self.data
        pstore[:version] = self.version
      end
    end

    # @group Callback methods

    # Callback method that is called when no data file was found. By default,
    # this implementation does nothing, but it should probably be overridden
    # by the subclass.
    #
    # @return [void]
    def no_data_found
    end

    # Callback method that is called when a version mismatch is detected. By
    # default, this implementation does nothing, but it should probably be
    # overridden by the subclass.
    #
    # @return [void]
    def version_mismatch_detected
    end

  private

    def pstore
      @pstore ||= PStore.new(self.filename)
    end

  end

end
