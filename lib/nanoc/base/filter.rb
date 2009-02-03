module Nanoc

  # Nanoc::Filter is responsible for filtering pages and textual assets. It is
  # the (abstract) superclass for all textual filters. Subclasses should
  # override the +run+ method.
  class Filter < Plugin

    # Deprecated
    EXTENSIONS_MAP = {}

    # A hash containing variables that will be made available during
    # filtering.
    attr_reader :assigns

    # Creates a new filter for the given item (page or asset) and assigns.
    #
    # +obj_rep+:: The page or asset representation (Nanoc::PageRep or
    #             Nanoc::AssetRep) that should be compiled by this filter.
    #
    # +other_assigns+:: A hash containing other variables that should be made
    #                   available during filtering.
    def initialize(a_assigns={})
      @assigns = a_assigns
    end

    # Runs the filter. This method returns the filtered content.
    #
    # +content+:: The unprocessed content that should be filtered.
    #
    # Subclasses must implement this method.
    def run(content, params={})
      raise NotImplementedError.new("Nanoc::Filter subclasses must implement #run")
    end

    class << self

      # Deprecated
      def extensions(*extensions) # :nodoc:
        # Initialize
        if !instance_variables.include?('@extensions') && !instance_variables.include?(:'@extensions')
          @extensions = []
        end

        if extensions.empty?
          @extensions
        else
          @extensions = extensions
          @extensions.each { |e| register_extension(e, self) }
        end
      end

      # Deprecated
      def extension(extension=nil) # :nodoc:
        # Initialize
        if !instance_variables.include?('@extensions') && !instance_variables.include?(:'@extensions')
          @extensions = []
        end

        if extension.nil?
          @extensions.first
        else
          @extensions = [ extension ]
          register_extension(extension, self)
        end
      end

      # Deprecated
      def register_extension(extension, klass)
        EXTENSIONS_MAP[extension] = klass
      end

      # Deprecated
      def with_extension(extension)
        EXTENSIONS_MAP[extension]
      end

    end

  end

end
