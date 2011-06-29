# encoding: utf-8

module Nanoc::Extra

  # A very simple representation of a version control system (VCS) that
  # abstracts the add, remove and move operations. It does not commit. This
  # class is primarily used by data sources that store data as flat files on
  # the disk.
  #
  # @abstract Subclass and override {#add}, {#remove} and {#move} to implement
  #   a custom VCS.
  class VCS

    extend Nanoc::PluginRegistry::PluginMethods

    # Adds the file with the given filename to the working copy.
    #
    # @param [String] filename The name of the file to add
    #
    # @return [void]
    #
    # @abstract
    def add(filename)
      not_implemented('add')
    end

    # Removes the file with the given filename from the working copy. When
    # this method is executed, the file should no longer be present on the
    # disk.
    #
    # @param [String] filename The name of the file to remove
    #
    # @return [void]
    #
    # @abstract
    def remove(filename)
      not_implemented('remove')
    end

    # Moves the file with the given filename to a new location. When this
    # method is executed, the original file should no longer be present on the
    # disk.
    #
    # @param [String] src The old filename
    #
    # @param [String] dst The new filename
    #
    # @return [void]
    #
    # @abstract
    def move(src, dst)
      not_implemented('move')
    end

  private

    def not_implemented(name)
      raise NotImplementedError.new(
        "#{self.class} does not override ##{name}, which is required for " +
        "this data source to be used."
      )
    end

  end

end
