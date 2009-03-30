module Nanoc

  # Nanoc::Filter is responsible for filtering pages and textual assets
  # (binary assets are filtered using Nanoc::BinaryFilter). It is the
  # (abstract) superclass for all textual filters. Subclasses should override
  # the +run+ method.
  class Filter < Plugin

    # Deprecated
    EXTENSIONS_MAP = {}

    # Creates a new filter for the given object (page or asset) and site.
    #
    # +kind+:: The kind of object that is passed. Can be either +:page+ or
    #          +:asset+.
    #
    # +obj_rep+:: A proxy for the page or asset representation (Nanoc::PageRep
    #             or Nanoc::AssetRep) that should be compiled by this filter.
    #
    # +obj+:: A proxy for the page or asset's page (Nanoc::Page or
    #         Nanoc::Asset).
    #
    # +site+:: The site (Nanoc::Site) this filter belongs to.
    #
    # +other_assigns+:: A hash containing other variables that should be made
    #                   available during filtering.
    def initialize(obj_rep, other_assigns={})
      # Determine kind
      @kind = obj_rep.is_a?(Nanoc::PageRep) ? :page : :asset

      # Set object
      @obj_rep = obj_rep
      @obj     = (@kind == :page ? @obj_rep.page : @obj_rep.asset)

      # Set page/asset and page/asset reps
      if @kind == :page
        @page       = @obj
        @page_rep   = @obj_rep
      else
        @asset      = @obj
        @asset_rep  = @obj_rep
      end

      # Set site
      @site = @obj.site

      # Set other assigns
      @other_assigns  = other_assigns
    end

    # Runs the filter. This method returns the filtered content.
    #
    # +content+:: The unprocessed content that should be filtered.
    #
    # Subclasses must implement this method.
    def run(content)
      raise NotImplementedError.new("Nanoc::Filter subclasses must implement #run")
    end

    # Returns a hash with data that should be available.
    def assigns
      @assigns ||= @other_assigns.merge({
        :_obj_rep   => @obj_rep,
        :_obj       => @obj,
        :page_rep   => @kind == :page  ? @page_rep.to_proxy  : nil,
        :page       => @kind == :page  ? @page.to_proxy      : nil,
        :asset_rep  => @kind == :asset ? @asset_rep.to_proxy : nil,
        :asset      => @kind == :asset ? @asset.to_proxy     : nil,
        :pages      => @site.pages.map    { |obj| obj.to_proxy },
        :assets     => @site.assets.map   { |obj| obj.to_proxy },
        :layouts    => @site.layouts.map  { |obj| obj.to_proxy },
        :config     => @site.config,
        :site       => @site
      })
    end

    # Returns the filename associated with the item that is being filtered.
    # The returned filename is in the format "page <path> (rep <name>)".
    def filename
      if assigns[:layout]
        "layout #{assigns[:layout].path}"
      elsif assigns[:page]
        "page #{assigns[:_obj].path} (rep #{assigns[:_obj_rep].name})"
      elsif assigns[:asset]
        "asset #{assigns[:_obj].path} (rep #{assigns[:_obj_rep].name})"
      else
        '?'
      end
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
