module Nanoc3

  # Nanoc3::Filter is responsible for filtering items. It is
  # the (abstract) superclass for all textual filters. Subclasses should
  # override the +run+ method.
  class Filter < Plugin

    # A hash containing variables that will be made available during
    # filtering.
    attr_reader :assigns

    # Creates a new filter with the given assigns.
    #
    # +a_assigns+:: A hash containing variables that should be made available
    #               during filtering.
    def initialize(a_assigns={})
      @assigns = a_assigns
    end

    # Sets the identifiers for this filter.
    def self.identifiers(*identifiers)
      Nanoc3::Filter.register(self, *identifiers)
    end

    # Sets the identifier for this filter.
    def self.identifier(identifier)
      Nanoc3::Filter.register(self, identifier)
    end

    # Registers the given class as a filter with the given identifier.
    def self.register(class_or_name, *identifiers)
      Nanoc3::Plugin.register(Nanoc3::Filter, class_or_name, *identifiers)
    end

    # Runs the filter. This method returns the filtered content.
    #
    # +content+:: The unprocessed content that should be filtered.
    #
    # Subclasses must implement this method.
    def run(content, params={})
      raise NotImplementedError.new("Nanoc3::Filter subclasses must implement #run")
    end

    # Returns the filename associated with the item that is being filtered.
    # The returned filename is in the format "item <identifier> (rep <name>)".
    def filename
      if @assigns[:layout]
        "layout #{assigns[:layout].identifier}"
      elsif @assigns[:_item]
        "item #{assigns[:_item].identifier} (rep #{assigns[:_item_rep].name})"
      else
        '?'
      end
    end

  end

end
