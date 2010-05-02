# encoding: utf-8

module Nanoc3

  # An abstract superclass for classes that need to store data to the
  # filesystem, such as checksums, cached compiled content and dependency
  # graphs.
  #
  # @abstract Subclasses should implement {#data} and {#data=}
  #
  # @api private
  class Store

    # Creates a new store for the given filename.
    #
    # @param [String] filename The name of the file where data will be loaded
    #   from and stored to.
    def initialize(filename)
      @filename = filename
    end

    # @return The data that should be written to the disk
    def data
      raise NotImplementedError.new("Nanoc3::Store subclasses must implement #data and #data=")
    end

    # @param new_data The data that has been loaded from the disk
    #
    # @return [void]
    def data=(new_data)
      raise NotImplementedError.new("Nanoc3::Store subclasses must implement #data and #data=")
    end

    # Loads the data from the filesystem into memory. This method will set the
    #   loaded data using the {#data=} method.
    #
    # @return [void]
    def load
      if self.loaded? || !File.file?(self.filename)
        self.loaded = true
        return
      end

      self.pstore.transaction { self.data = self.pstore[:data] }
      self.loaded = true
    end

    # Stores the data contained in memory to the filesystem. This method will
    #   use the {#data} method to fetch the data that should be written.
    #
    # @return [void]
    def store
      FileUtils.mkdir_p(File.dirname(self.filename))
      self.pstore.transaction { self.pstore[:data] = self.data }
    end

  protected

    attr_reader :filename

    attr_accessor :loaded
    def loaded? ; !!@loaded ; end

    def pstore
      require 'pstore'
      @pstore ||= PStore.new(self.filename)
    end

  end

end
