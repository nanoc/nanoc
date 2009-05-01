module Nanoc3

  # A Nanoc3::ItemRep is a single representation (rep) of an item
  # (Nanoc3::Item). An item can have multiple representations. A representation
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

    # The item (Nanoc3::Item) to which this representation belongs.
    attr_reader   :item

    # This item representation's unique name.
    attr_reader   :name

    # Indicates whether this rep is forced to be dirty because of outdated
    # dependencies.
    attr_accessor :force_outdated

    # Indicates whether this rep's output file has changed the last time it
    # was compiled.
    attr_accessor :modified
    alias_method :modified?, :modified

    # Indicates whether this rep's output file was created the last time it
    # was compiled.
    attr_accessor :created
    alias_method :created?, :created

    # Indicates whether this rep has already been compiled.
    attr_accessor :compiled
    alias_method :compiled?, :compiled

    # Indicates whether this rep's compiled content has been written during
    # the current or last compilation session.
    attr_reader :written
    alias_method :written?, :written

    # The item rep's path, as used when being linked to. It starts with a
    # slash and it is relative to the output directory. It does not include
    # the path to the output directory. It will not include the filename if
    # the filename is an index filename.
    attr_accessor :path

    # The item rep's raw path. It is relative to the current working directory
    # and includes the path to the output directory. It also includes the
    # filename, even if it is an index filename.
    attr_accessor :raw_path

    # A hash containing this rep's content for each snapshot. Snapshot names
    # can be anything; some predefines ones are +:raw+, +:pre+, +:post+ and
    # +:last+.
    attr_accessor :content

    # Creates a new item representation for the given item.
    #
    # +item+:: The item (Nanoc3::Item) to which the new representation will
    #          belong.
    #
    # +name+:: The unique name for the new item representation.
    def initialize(item, name)
      # Set primary attributes
      @item = item
      @name = name

      # Initialize content
      @content = {
        :raw  => @item.content,
        :last => @item.content,
        :pre  => @item.content
      }

      # Reset flags
      @compiled       = false
      @modified       = false
      @created        = false
      @written        = false
      @force_outdated = false
    end

    # Returns true if this item rep's output file is outdated and must be
    # regenerated, false otherwise.
    def outdated?
      # Outdated if we don't know
      return true if @item.mtime.nil?

      # Outdated if the dependency tracker says so
      return true if @force_outdated

      # Outdated if compiled file doesn't exist
      return true if !File.file?(raw_path) && !@item[:skip_output]

      # Get compiled mtime
      compiled_mtime = File.stat(raw_path).mtime if !@item[:skip_output]

      # Outdated if file too old
      return true if !@item[:skip_output] && @item.mtime > compiled_mtime

      # Outdated if layouts outdated
      return true if @item.site.layouts.any? do |l|
        l.mtime.nil? || (!@item[:skip_output] && l.mtime > compiled_mtime)
      end

      # Outdated if code outdated
      return true if @item.site.code.mtime.nil?
      return true if !@item[:skip_output] && @item.site.code.mtime > compiled_mtime

      return false
    end

    # Returns the assignments that should be available when compiling the content.
    def assigns
      {
        :content    => @content[:last],
        :item       => self.item,
        :item_rep   => self,
        :items      => self.item.site.items,
        :layouts    => self.item.site.layouts,
        :config     => self.item.site.config,
        :site       => self.item.site
      }
    end

    # Returns the item representation content at the given snapshot.
    #
    # +snapshot+:: The snapshot from which the content should be fetched. To
    #              get the raw, uncompiled content, use +:raw+.
    def content_at_snapshot(snapshot=:pre)
      Nanoc3::NotificationCenter.post(:visit_started, self)
      @item.site.compiler.compile_rep(self) unless compiled?
      Nanoc3::NotificationCenter.post(:visit_ended, self)

      @content[snapshot]
    end

    # Runs the item content through the given filter with the given arguments.
    def filter(filter_name, filter_args={})
      # Create filter
      klass = Nanoc3::Filter.named(filter_name)
      raise Nanoc3::Errors::UnknownFilterError.new(filter_name) if klass.nil?
      filter = klass.new(assigns)

      # Run filter
      Nanoc3::NotificationCenter.post(:filtering_started, self, filter_name)
      @content[:last] = filter.run(@content[:last], filter_args)
      Nanoc3::NotificationCenter.post(:filtering_ended, self, filter_name)

      # Create snapshot
      snapshot(@content[:post] ? :post : :pre)
    end

    # Lays out the item using the given layout.
    def layout(layout_identifier)
      # Get layout
      layout ||= @item.site.layouts.find { |l| l.identifier == layout_identifier.cleaned_identifier }
      raise Nanoc3::Errors::UnknownLayoutError.new(layout_identifier) if layout.nil?

      # Get filter name
      filter_name  = @item.site.compiler.filter_name_for_layout(layout)
      raise Nanoc3::Errors::CannotDetermineFilterError.new(layout_identifier) if filter_name.nil?

      # Get filter class
      filter_class = Nanoc3::Filter.named(filter_name)
      raise Nanoc3::Errors::UnknownFilterError.new(filter_name) if filter_class.nil?

      # Create filter
      filter = filter_class.new(assigns.merge({ :layout => layout }))

      # Create "pre" snapshot
      snapshot(:pre)

      # Layout
      Nanoc3::NotificationCenter.post(:filtering_started, self, filter_name)
      @content[:last] = filter.run(layout.content)
      Nanoc3::NotificationCenter.post(:filtering_ended,   self, filter_name)

      # Create "post" snapshot
      snapshot(:post)
    end

    # Creates a snapshot of the current compiled item content.
    def snapshot(snapshot_name)
      @content[snapshot_name] = @content[:last]
    end

    # Writes the item rep's compiled content to the rep's output file.
    def write
      # Create parent directory
      FileUtils.mkdir_p(File.dirname(self.raw_path))

      # Check if file will be created
      @created = !File.file?(self.raw_path)

      # Remember old content
      if File.file?(self.raw_path)
        old_content = File.read(self.raw_path)
      end

      # Write
      File.open(self.raw_path, 'w') { |io| io.write(@content[:last]) }
      @written = true

      # Check if file was modified
      @modified = File.read(self.raw_path) != old_content
    end

    def inspect
      "<#{self.class} name=#{self.name} item.identifier=#{self.item.identifier}>"
    end

  end

end
