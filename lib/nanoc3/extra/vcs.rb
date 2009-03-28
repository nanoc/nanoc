module Nanoc3::Extra

  # Nanoc3::Extra::VCS is a very simple representation of a version control
  # system that abstracts the add, remove and move operations. It does not
  # commit. This class is primarily used by data sources that store data as
  # flat files on the disk.
  #
  # This is the abstract superclass for all VCSes. Subclasses should implement
  # the indicated methods. 
  class VCS < Nanoc3::Plugin

    # Adds the file with the given filename to the working copy.
    #
    # Subclasses must implement this method.
    def add(filename)
      not_implemented('add')
    end

    # Removes the file with the given filename from the working copy. When
    # this method is executed, the file should no longer be present on the
    # disk.
    #
    # Subclasses must implement this method.
    def remove(filename)
      not_implemented('remove')
    end

    # Moves the file with the given filename to a new location. When this
    # method is executed, the original file should no longer be present on the
    # disk.
    #
    # Subclasses must implement this method.
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
