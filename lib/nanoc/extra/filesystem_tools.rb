# encoding: utf-8

module Nanoc::Extra

  # Contains useful functions for managing the filesystem.
  #
  # @api private
  module FilesystemTools

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
    def all_files_in(dir_name, recursion_limit=10)
      Dir[dir_name + '/**/*'].map do |fn|
        if File.symlink?(fn) && recursion_limit > 0
          dest = File.readlink(fn)
          if File.file?(dest)
            dest
          else
            all_files_in(dest, recursion_limit-1)
          end
        elsif File.file?(fn)
          fn
        end
      end.compact.flatten
    end
    module_function :all_files_in

  end

end
