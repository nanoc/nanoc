# encoding: utf-8

module Nanoc::Extra

  # Contains useful functions for managing the filesystem.
  #
  # @api private
  module FilesystemTools

    # Error that is raised when too many symlink indirections are encountered.
    #
    # @api private
    class MaxSymlinkDepthExceededError < ::Nanoc::Errors::GenericTrivial

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
    #
    # @api private
    class UnsupportedFileTypeError < ::Nanoc::Errors::GenericTrivial

      # @return [String] The filename of the file whose type is not supported
      attr_reader :filename

      # @param [String] filename The filename of the file whose type is not
      #   supported
      def initialize(filename)
        @filename = filename
        super("The file at #{filename} is of an unsupported type (expected file, directory or link, but it is #{File.ftype(filename)}")
      end

    end

    # Returns all files in the given directory and directories below it,
    # following symlinks up to a maximum of `recursion_limit` times.
    #
    # @param [String] dir_name The name of the directory whose contents to
    #   fetch
    #
    # @param [Integer] recursion_limit The maximum number of times to
    #   recurse into a symlink to a directory
    #
    # @return [Array<String>] A list of filenames
    #
    # @raise [MaxSymlinkDepthExceededError] if too many indirections are
    #   encountered while resolving symlinks
    #
    # @raise [UnsupportedFileTypeError] if a file of an unsupported type is
    #   detected (something other than file, directory or link)
    def all_files_in(dir_name, recursion_limit = 10)
      Dir[dir_name + '/**/*'].map do |fn|
        case File.ftype(fn)
        when 'link'
          if 0 == recursion_limit
            raise MaxSymlinkDepthExceededError.new(fn)
          else
            absolute_target = resolve_symlink(fn)
            if File.file?(absolute_target)
              fn
            else
              all_files_in(absolute_target, recursion_limit - 1).map do |sfn|
                fn + sfn[absolute_target.size..-1]
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
    module_function :all_files_in

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
      absolute_target = File.expand_path(target, File.dirname(filename))

      case File.ftype(absolute_target)
      when 'link'
        if 0 == recursion_limit
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
    module_function :resolve_symlink

  end

end
