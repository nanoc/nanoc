# encoding: utf-8

module Nanoc3

  # Nanoc3::Filter is responsible for filtering items. It is
  # the (abstract) superclass for all textual filters. Subclasses should
  # override the +run+ method.
  class Filter < Plugin

    # A hash containing variables that will be made available during
    # filtering.
    attr_reader :assigns

    # @param [Hash] a_assigns A hash containing variables that should be made
    #   available during filtering.
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
    # Subclasses must implement this method.
    #
    # @param [String] content The unprocessed content that should be filtered.
    #
    # @param [Hash] params A hash containing parameters. Filter subclasses can
    #   use these parameters to allow modifying the filter's behaviour.
    #
    def run(content, params={})
      raise NotImplementedError.new("Nanoc3::Filter subclasses must implement #run")
    end

    # @return [String] The filename associated with the item that is being
    # filtered. It is in the format "item <identifier> (rep <name>)".
    def filename
      if assigns[:layout]
        "layout #{assigns[:layout].identifier}"
      elsif assigns[:item]
        "item #{assigns[:item].identifier} (rep #{assigns[:item_rep].name})"
      else
        '?'
      end
    end

  end

end
