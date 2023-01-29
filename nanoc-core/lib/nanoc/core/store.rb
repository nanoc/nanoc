# frozen_string_literal: true

module Nanoc
  module Core
    # An abstract superclass for classes that need to store data to the
    # filesystem, such as checksums, cached compiled content and dependency
    # graphs.
    #
    # Each store has a version number. When attempting to load data from a store
    # that has an incompatible version number, no data will be loaded.
    #
    # @api private
    class Store
      include Nanoc::Core::ContractsSupport

      # Logic for building tmp path from active environment and store name
      # @api private
      contract C::KeywordArgs[config: Nanoc::Core::Configuration, store_name: String] => C::AbsolutePathString
      def self.tmp_path_for(store_name:, config:)
        File.absolute_path(
          File.join(tmp_path_prefix(config.output_dir), store_name),
          config.dir,
        )
      end

      contract String => String
      def self.tmp_path_prefix(output_dir)
        dir = Digest::SHA1.hexdigest(output_dir)[0..12]
        File.join('tmp', 'nanoc', dir)
      end

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
        raise NotImplementedError.new('Nanoc::Core::Store subclasses must implement #data and #data=')
      end

      # @param new_data The data that has been loaded from the disk
      #
      # @abstract This method must be implemented by the subclass.
      #
      # @return [void]
      def data=(new_data) # rubocop:disable Lint/UnusedMethodArgument
        raise NotImplementedError.new('Nanoc::Core::Store subclasses must implement #data and #data=')
      end

      # Loads the data from the filesystem into memory. This method will set the
      #   loaded data using the {#data=} method.
      #
      # @return [void]
      def load
        Nanoc::Core::Instrumentor.call(:store_loaded, self.class) do
          load_uninstrumented
        end
      end

      # Stores the data contained in memory to the filesystem. This method will
      #   use the {#data} method to fetch the data that should be written.
      #
      # @return [void]
      def store
        # NOTE: Yes, the “store stored” name is a little silly. Maybe stores
        # need to be renamed to databases or so.
        Nanoc::Core::Instrumentor.call(:store_stored, self.class) do
          store_uninstrumented
        end
      end

      private

      def load_uninstrumented
        unsafe_load_uninstrumented
      rescue
        # An error occurred! Remove the database and try again
        FileUtils.rm_f(version_filename)
        FileUtils.rm_f(data_filename)

        # Try again
        unsafe_load_uninstrumented
      end

      def store_uninstrumented
        FileUtils.mkdir_p(File.dirname(filename))

        write_obj_to_file(version_filename, version)
        write_obj_to_file(data_filename, data)

        # Remove old file (back from the PStore days), if there are any.
        FileUtils.rm_f(filename)
      end

      # Unsafe, because it can throw exceptions.
      def unsafe_load_uninstrumented
        # If there is no database, no point in loading anything
        return unless File.file?(version_filename)

        # Check if store version is the expected version. If it is not, don’t
        # load.
        read_version = read_obj_from_file(version_filename)
        return if read_version != version

        # Load data
        self.data = read_obj_from_file(data_filename)
      end

      def write_obj_to_file(filename, obj)
        data = Marshal.dump(obj)
        compressed_data = Zlib::Deflate.deflate(data, Zlib::BEST_SPEED)
        write_data_to_file(filename, compressed_data)
      end

      def read_obj_from_file(fn)
        compressed_data = File.binread(fn)
        data = Zlib::Inflate.inflate(compressed_data)
        Marshal.load(data)
      end

      def version_filename
        "#{filename}.version.db"
      end

      def data_filename
        "#{filename}.data.db"
      end

      def write_data_to_file(filename, data)
        basename = File.basename(filename)
        dirname = File.dirname(filename)

        # Write to a temporary file first, and then (atomically) move it into
        # place.
        Tempfile.open(".#{basename}", dirname) do |temp_file|
          temp_file.binmode

          # Write the data as a stream, because File.binwrite can’t
          # necessarily deal with writing that much data all at once.
          #
          # See https://github.com/nanoc/nanoc/issues/1635.
          reader = StringIO.new(data)
          IO.copy_stream(reader, temp_file)
          temp_file.close

          # Rename (atomic)
          File.rename(temp_file.path, filename)
        end
      end
    end
  end
end
