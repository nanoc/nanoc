# frozen_string_literal: true

class Nanoc::DataSources::Filesystem < Nanoc::DataSource
  # Contains useful functions for managing the filesystem.
  #
  # @api private
  module Tools
    # Error that is raised when too many symlink indirections are encountered.
    class MaxSymlinkDepthExceededError < ::Nanoc::Core::TrivialError
      # @return [String] The last filename that was attempted to be
      #   resolved before giving up
      attr_reader :filename

      # @param [String] filename The last filename that was attempted to be
      #   resolved before giving up
      def initialize(filename)
        @filename = filename
        super("Too many indirections while resolving symlinks. I gave up after finding out #{filename} was yet another symlink. Sorry!")
      end
    end

    # Error that is raised when a file of an unknown type is encountered
    # (something other than file, directory or link).
    class UnsupportedFileTypeError < ::Nanoc::Core::TrivialError
      # @return [String] The filename of the file whose type is not supported
      attr_reader :filename

      # @param [String] filename The filename of the file whose type is not
      #   supported
      def initialize(filename)
        @filename = filename
        super("The file at #{filename} is of an unsupported type (expected file, directory or link, but it is #{File.ftype(filename)}")
      end
    end

    module_function

    # Returns all files in the given directory and directories below it,
    # following symlinks up to a maximum of `recursion_limit` times.
    #
    # @param [String] dir_name The name of the directory whose contents to
    #   fetch
    #
    # @param [String, Array, nil] extra_files The list of extra patterns
    #   to extend the file search for files not found by default, example
    #   "**/.{htaccess,htpasswd}"
    #
    # @param [Integer] recursion_limit The maximum number of times to
    #   recurse into a symlink to a directory
    #
    # @return [Array<String>] A list of file names
    #
    # @raise [MaxSymlinkDepthExceededError] if too many indirections are
    #   encountered while resolving symlinks
    #
    # @raise [UnsupportedFileTypeError] if a file of an unsupported type is
    #   detected (something other than file, directory or link)
    def all_files_in(dir_name, extra_files, recursion_limit = 10)
      all_files_and_dirs_in(dir_name, extra_files).map do |fn|
        case File.ftype(fn)
        when 'link'
          if recursion_limit.zero?
            raise MaxSymlinkDepthExceededError.new(fn)
          else
            absolute_target = resolve_symlink(fn)
            if File.file?(absolute_target)
              fn
            else
              all_files_in(absolute_target, extra_files, recursion_limit - 1).map do |sfn|
                fn + sfn[absolute_target.size..]
              end
            end
          end
        when 'file'
          fn
        when 'directory'
          nil
        else
          raise UnsupportedFileTypeError.new(fn)
        end
      end.compact.flatten
    end

    # Expands the path (including resolving ~ for home directory) and returns
    # a relative path to the expanded path.
    def expand_and_relativize_path(path)
      from = Pathname.new(Dir.getwd)
      to = Pathname.new(File.expand_path(path))

      to.relative_path_from(from).to_s
    end

    # Returns all files and directories in the given directory and
    # directories below it.
    #
    # @param [String] dir_name The name of the directory whose contents to
    #   fetch
    #
    # @param [String, Array, nil] extra_files The list of extra patterns
    #   to extend the file search for files not found by default, example
    #   "**/.{htaccess,htpasswd}"
    #
    # @return [Array<String>] A list of files and directories
    #
    # @raise [Nanoc::Core::TrivialError] when pattern can not be handled
    def all_files_and_dirs_in(dir_name, extra_files)
      base_patterns = ["#{dir_name}/**/*"]

      extra_patterns =
        case extra_files
        when nil
          []
        when String
          ["#{dir_name}/#{extra_files.dup.delete_prefix('/')}"]
        when Array
          extra_files.map { |extra_file| "#{dir_name}/#{extra_file.dup.delete_prefix('/')}" }
        else
          raise(
            Nanoc::Core::TrivialError,
            "Do not know how to handle extra_files: #{extra_files.inspect}",
          )
        end

      patterns = base_patterns + extra_patterns
      Dir.glob(patterns)
    end

    # Resolves the given symlink into an absolute path.
    #
    # @param [String] filename The filename of the symlink to resolve
    #
    # @param [Integer] recursion_limit The maximum number of times to recurse
    #   into a symlink
    #
    # @return [String] The absolute resolved filename of the symlink target
    #
    # @raise [MaxSymlinkDepthExceededError] if too many indirections are
    #   encountered while resolving symlinks
    #
    # @raise [UnsupportedFileTypeError] if a file of an unsupported type is
    #   detected (something other than file, directory or link)
    def resolve_symlink(filename, recursion_limit = 5)
      target = File.readlink(filename)
      absolute_target = Nanoc::Core::Utils.expand_path_without_drive_identifier(target, File.dirname(filename))

      case File.ftype(absolute_target)
      when 'link'
        if recursion_limit.zero?
          raise MaxSymlinkDepthExceededError.new(absolute_target)
        else
          resolve_symlink(absolute_target, recursion_limit - 1)
        end
      when 'file', 'directory'
        absolute_target
      else
        raise UnsupportedFileTypeError.new(absolute_target)
      end
    end

    # Reads the content of the file with the given name and returns a string
    # in UTF-8 encoding. The original encoding of the string is derived from
    # the default external encoding, but this can be overridden by the
    # “encoding” configuration attribute in the data source configuration.
    def read_file(filename, config:)
      # Read
      begin
        data = File.read(filename)
      rescue => e
        raise Errors::FileUnreadable.new(filename, e)
      end

      # Set original encoding, if any
      if config && config[:encoding]
        original_encoding = Encoding.find(config[:encoding])
        data.force_encoding(config[:encoding])
      else
        original_encoding = data.encoding
      end

      # Set encoding to UTF-8
      begin
        data.encode!('UTF-8')
      rescue
        raise Errors::InvalidEncoding.new(filename, original_encoding)
      end

      # Verify
      unless data.valid_encoding?
        raise Errors::InvalidEncoding.new(filename, original_encoding)
      end

      # Remove UTF-8 BOM (ugly)
      data.delete!("\xEF\xBB\xBF")

      data
    end
  end
end
