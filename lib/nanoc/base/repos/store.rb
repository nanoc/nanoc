# frozen_string_literal: true

module Nanoc::Int
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
    include Nanoc::Int::ContractsSupport

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

    # Logic for building tmp path from active environment and store name
    # @api private
    contract C::KeywordArgs[site: C::Maybe[Nanoc::Int::Site], store_name: String] => String
    def self.tmp_path_for(store_name:, site:)
      # FIXME: disallow site from being nil
      output_dir = site ? site.config.output_dir : ''
      File.join(tmp_path_prefix(output_dir), store_name)
    end

    def self.tmp_path_prefix(output_dir)
      dir = Digest::SHA1.hexdigest(output_dir)[0..12]
      File.join('tmp', 'nanoc', dir)
    end

    # @group Loading and storing data

    # @return The data that should be written to the disk
    #
    # @abstract This method must be implemented by the subclass.
    def data
      raise NotImplementedError.new('Nanoc::Int::Store subclasses must implement #data and #data=')
    end

    # @param new_data The data that has been loaded from the disk
    #
    # @abstract This method must be implemented by the subclass.
    #
    # @return [void]
    def data=(new_data) # rubocop:disable Lint/UnusedMethodArgument
      raise NotImplementedError.new('Nanoc::Int::Store subclasses must implement #data and #data=')
    end

    # Loads the data from the filesystem into memory. This method will set the
    #   loaded data using the {#data=} method.
    #
    # @return [void]
    def load
      return unless File.file?(filename)

      begin
        pstore.transaction do
          return if pstore[:version] != version
          self.data = pstore[:data]
        end
      rescue
        FileUtils.rm_f(filename)
        load
      end
    end

    # Stores the data contained in memory to the filesystem. This method will
    #   use the {#data} method to fetch the data that should be written.
    #
    # @return [void]
    def store
      FileUtils.mkdir_p(File.dirname(filename))

      pstore.transaction do
        pstore[:data]    = data
        pstore[:version] = version
      end
    end

    private

    def pstore
      @pstore ||= PStore.new(filename)
    end
  end
end
