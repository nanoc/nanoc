module Nanoc

  # Nanoc::Defaults represent the default attributes for a given set of
  # objects in the site. It is basically a hash with an optional modification
  # time.
  class Defaults

    # Th site where this set of defaults belongs to.
    attr_accessor :site

    # A hash containing the default attributes.
    attr_reader   :attributes

    # The time when this set of defaults was last modified.
    attr_reader   :mtime

    # Creates a new set of defaults.
    #
    # +attributes+:: The hash containing the metadata that individual objects
    #                will override.
    #
    # +mtime+:: The time when the defaults were last modified (optional).
    def initialize(attributes, mtime=nil)
      @attributes = attributes.clean
      @mtime      = mtime
    end

  end

end
