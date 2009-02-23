module Nanoc

  # A Nanoc::ItemRep is a single representation (rep) of an item
  # (Nanoc::Item). An item can have multiple representations. A representation
  # has its own output file. A single item can therefore have multiple output
  # files, each run through a different set of filters with a different
  # layout.
  #
  # An item representation is observable. The following events will be
  # notified:
  #
  # * :compilation_started
  # * :compilation_ended
  # * :filtering_started
  # * :filtering_ended
  # * :visit_started
  # * :visit_ended
  #
  # The compilation-related events have one parameters (the item
  # representation); the filtering-related events have two (the item
  # representation, and a symbol containing the filter class name).
  class ItemRep

    # The item (Nanoc::Item) to which this representation belongs.
    attr_reader   :item

    # This item representation's unique name.
    attr_reader   :name

    # Indicates whether this rep is forced to be dirty because of outdated
    # dependencies.
    attr_accessor :force_outdated

    # Indicates whether this rep's output file has changed the last time it
    # was compiled.
    attr_accessor :modified

    # Indicates whether this rep's output file was created the last time it
    # was compiled.
    attr_accessor :created

    # Indicates whether this rep has already been compiled.
    attr_accessor :compiled

    # A hash containing this rep's content for each snapshot. Snapshot names
    # can be anything; some predefines ones are +:raw+, +:pre+, +:post+ and
    # +:last+.
    attr_accessor :content

    # Creates a new item representation for the given item.
    #
    # +item+:: The item (Nanoc::Item) to which the new representation will
    #          belong.
    #
    # +name+:: The unique name for the new item representation.
    def initialize(item, name)
      # Set primary attributes
      @item           = item
      @name           = name

      # Initialize content
      @content        = {}

      # Reset flags
      @compiled       = false
      @modified       = false
      @created        = false
      @force_outdated = false
    end

    # Returns this representation's type (either :page_rep or :asset_rep).
    # Should be overridden in subclasses.
    def type
      nil
    end

    # Returns a proxy (Nanoc::ItemRepProxy) for this item representation.
    def to_proxy
      @proxy ||= ItemRepProxy.new(self)
    end

    # Returns true if this item rep's output file was created during the last
    # compilation session, or false if the output file did already exist.
    def created?
      @created
    end

    # Returns true if this item rep's output file was modified during the last
    # compilation session, or false if the output file wasn't changed.
    def modified?
      @modified
    end

    # Returns true if this item rep has been compiled, false otherwise.
    def compiled?
      @compiled
    end

    # Returns the path to the output file, including the path to the output
    # directory specified in the site configuration, and including the
    # filename and extension.
    def raw_path
      @raw_path ||= @item.site.router.raw_path_for(self)
    end

    # Returns the path to the output file as it would be used in a web
    # browser: starting with a slash (representing the web root), and only
    # including the filename and extension if they cannot be ignored (i.e.
    # they are not in the site configuration's list of index files).
    def path
      Nanoc::NotificationCenter.post(:visit_started, self)
      Nanoc::NotificationCenter.post(:visit_ended,   self)

      @item.site.compiler.compile_rep(self, false)

      @path ||= @item.site.router.path_for(self)
    end

    # Returns true if this item rep's output file is outdated and must be
    # regenerated, false otherwise.
    def outdated?
      # Outdated if we don't know
      return true if @item.mtime.nil?

      # Outdated if the dependency tracker says so
      return true if @force_outdated

      # Outdated if compiled file doesn't exist
      return true if !File.file?(raw_path) && !@item.attribute_named(:skip_output)

      # Get compiled mtime
      compiled_mtime = File.stat(raw_path).mtime if !@item.attribute_named(:skip_output)

      # Outdated if file too old
      return true if !@item.attribute_named(:skip_output) && @item.mtime > compiled_mtime

      # Outdated if layouts outdated
      return true if @item.site.layouts.any? do |l|
        l.mtime.nil? || (!@item.attribute_named(:skip_output) && l.mtime > compiled_mtime)
      end

      # Outdated if code outdated
      return true if @item.site.code.mtime.nil?
      return true if !@item.attribute_named(:skip_output) && @item.site.code.mtime > compiled_mtime

      return false
    end

    # Returns the assignments that should be available when compiling the content.
    def assigns
      {
        :_obj_rep   => self,
        :_obj       => self.item,
        :page_rep   => self.is_a?(Nanoc::PageRep)  ? self.to_proxy      : nil,
        :page       => self.is_a?(Nanoc::PageRep)  ? self.item.to_proxy : nil,
        :asset_rep  => self.is_a?(Nanoc::AssetRep) ? self.to_proxy      : nil,
        :asset      => self.is_a?(Nanoc::AssetRep) ? self.item.to_proxy : nil,
        :pages      => self.item.site.pages.map   { |obj| obj.to_proxy },
        :assets     => self.item.site.assets.map  { |obj| obj.to_proxy },
        :layouts    => self.item.site.layouts.map { |obj| obj.to_proxy },
        :config     => self.item.site.config,
        :site       => self.item.site
      }
    end

    # Returns the item representation content at the given snapshot.
    #
    # +snapshot+:: The snapshot from which the content should be fetched. To
    #              get the raw, uncompiled content, use +:raw+.
    def content_at_snapshot(snapshot=:pre)
      Nanoc::NotificationCenter.post(:visit_started, self)
      @item.site.compiler.compile_rep(self, false) unless @content[snapshot]
      Nanoc::NotificationCenter.post(:visit_ended, self)

      @content[snapshot]
    end

    # Runs the item content through the given filter with the given arguments.
    def filter(filter_name, filter_args={})
      # Create filter
      klass = Nanoc::Filter.named(filter_name)
      raise Nanoc::Errors::UnknownFilterError.new(filter_name) if klass.nil?
      filter = klass.new(assigns)

      # Run filter
      Nanoc::NotificationCenter.post(:filtering_started, self, klass.identifier)
      if filter.method(:run).arity == -2
        @content[:last] = filter.run(@content[:last], filter_args)
      else
        @content[:last] = filter.run(@content[:last])
      end
      Nanoc::NotificationCenter.post(:filtering_ended, self, klass.identifier)

      # Create snapshot
      snapshot(@content[:post] ? :post : :pre)
    end

    # Lays out the item using the given layout.
    def layout(layout_identifier)
      # Get layout
      layout ||= @item.site.layouts.find { |l| l.identifier == layout_identifier.cleaned_identifier }
      raise Nanoc::Errors::UnknownLayoutError.new(layout_identifier) if layout.nil?

      # Create filter
      klass = layout.filter_class
      raise Nanoc::Errors::CannotDetermineFilterError.new(layout.identifier) if klass.nil?
      filter = klass.new(assigns.merge({ :layout => layout.to_proxy }))

      # Create "pre" snapshot
      snapshot(:pre)

      # Layout
      Nanoc::NotificationCenter.post(:filtering_started, self, klass.identifier)
      @content[:last] = filter.run(layout.content)
      Nanoc::NotificationCenter.post(:filtering_ended,   self, klass.identifier)
    end

    # Creates a snapshot of the current compiled item content.
    def snapshot(snapshot_name)
      @content[snapshot_name] = @content[:last]
    end

    # Writes the item rep's compiled content to the rep's output file.
    def write
      FileUtils.mkdir_p(File.dirname(self.raw_path))
      File.open(self.raw_path, 'w') { |io| io.write(@content[:last]) }
    end

  end

end
