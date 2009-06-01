# encoding: utf-8

module Nanoc3::Extra

  # Nanoc3::Extra::VCS is a very simple representation of a version control
  # system that abstracts the add, remove and move operations. It does not
  # commit. This class is primarily used by data sources that store data as
  # flat files on the disk.
  #
  # This is the abstract superclass for all VCSes. Subclasses should implement
  # the indicated methods. 
  class VCS < Nanoc3::Plugin

    # Sets the identifiers for this VCS.
    def self.identifiers(*identifiers)
      Nanoc3::Extra::VCS.register(self, *identifiers)
    end

    # Sets the identifier for this VCS.
    def self.identifier(identifier)
      Nanoc3::Extra::VCS.register(self, identifier)
    end

    # Registers the given class as a VCS with the given identifier.
    def self.register(class_or_name, *identifiers)
      Nanoc3::Plugin.register(Nanoc3::Extra::VCS, class_or_name, *identifiers)
    end

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
