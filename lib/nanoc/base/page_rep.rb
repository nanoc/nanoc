module Nanoc

  # A Nanoc::PageRep is a single representation (rep) of a page (Nanoc::Page).
  # A page can have multiple representations. A representation has its own
  # attributes and its own output file. A single page can therefore have
  # multiple output files, each run through a different set of filters with a
  # different layout.
  #
  # A page representation is observable. The following events will be
  # notified:
  #
  # * :compilation_started
  # * :compilation_ended
  # * :filtering_started
  # * :filtering_ended
  #
  # The compilation-related events have one parameters (the page
  # representation); the filtering-related events have two (the page
  # representation, and a symbol containing the filter class name).
  class PageRep

    # The page (Nanoc::Page) to which this representation belongs.
    attr_reader   :page

    # A hash containing this page representation's attributes.
    attr_accessor :attributes

    # This page representation's unique name.
    attr_reader   :name

    # Creates a new page representation for the given page and with the given
    # attributes.
    #
    # +page+:: The page (Nanoc::Page) to which the new representation will
    #          belong.
    #
    # +attributes+:: A hash containing the new page representation's
    #                attributes. This hash must have been run through
    #                Hash#clean before using it here.
    #
    # +name+:: The unique name for the new page representation.
    def initialize(page, attributes, name)
      # Set primary attributes
      @page           = page
      @attributes     = attributes
      @name           = name

      # Get page content from page
      @content        = { :pre => nil, :post => nil }

      # Reset flags
      @compiled       = false
      @modified       = false
      @created        = false
    end

    # Returns a proxy (Nanoc::PageRepProxy) for this page representation.
    def to_proxy
      @proxy ||= PageRepProxy.new(self)
    end

    # Returns true if this page rep's output file was created during the last
    # compilation session, or false if the output file did already exist.
    def created?
      @created
    end

    # Returns true if this page rep's output file was modified during the last
    # compilation session, or false if the output file wasn't changed.
    def modified?
      @modified
    end

    # Returns true if this page rep has been compiled, false otherwise.
    def compiled?
      @compiled
    end

    # Returns true if this page rep's output file is outdated and must be
    # regenerated, false otherwise.
    def outdated?
      # Outdated if we don't know
      return true if @page.mtime.nil?

      # Outdated if compiled file doesn't exist
      return true if !File.file?(disk_path)

      # Get compiled mtime
      compiled_mtime = File.stat(disk_path).mtime

      # Outdated if file too old
      return true if @page.mtime > compiled_mtime

      # Outdated if layouts outdated
      return true if @page.site.layouts.any? do |l|
        l.mtime.nil? or l.mtime > compiled_mtime
      end

      # Outdated if page defaults outdated
      return true if @page.site.page_defaults.mtime.nil?
      return true if @page.site.page_defaults.mtime > compiled_mtime

      # Outdated if code outdated
      return true if @page.site.code.mtime.nil?
      return true if @page.site.code.mtime > compiled_mtime

      return false
    end

    # Returns the path to the output file, including the path to the output
    # directory specified in the site configuration, and including the
    # filename and extension.
    def disk_path
      @disk_path ||= @page.site.router.disk_path_for(self)
    end

    # Returns the path to the output file as it would be used in a web
    # browser: starting with a slash (representing the web root), and only
    # including the filename and extension if they cannot be ignored (i.e.
    # they are not in the site configuration's list of index files).
    def web_path
      @web_path ||= @page.site.router.web_path_for(self)
    end

    # Returns the attribute with the given name. This method will look in
    # several places for the requested attribute:
    #
    # 1. This page representation's attributes;
    # 2. The attributes of this page representation's page;
    # 3. The page defaults' representation corresponding to this page
    #    representation;
    # 4. The page defaults in general;
    # 5. The hardcoded page defaults, if everything else fails.
    def attribute_named(name)
      # Check in here
      return @attributes[name] if @attributes.has_key?(name)

      # Check in page
      return @page.attributes[name] if @page.attributes.has_key?(name)

      # Check in page defaults' page rep
      page_default_reps = @page.site.page_defaults.attributes[:reps] || {}
      page_default_rep  = page_default_reps[@name] || {}
      return page_default_rep[name] if page_default_rep.has_key?(name)

      # Check in site defaults (global)
      page_defaults_attrs = @page.site.page_defaults.attributes
      return page_defaults_attrs[name] if page_defaults_attrs.has_key?(name)

      # Check in hardcoded defaults
      return Nanoc::Page::DEFAULTS[name]
    end

    # Returns the page representation content at the given stage.
    #
    # +stage+:: The stage at which the content should be fetched. Can be
    #           either +:pre+ or +:post+. To get the raw, uncompiled content,
    #           use Nanoc::Page#content.
    def content(stage=:pre)
      compile(stage == :post, true, false)

      @content[stage]
    end

    # Returns the layout used for this page representation.
    def layout
      # Check whether layout is present
      return nil if attribute_named(:layout).nil?

      # Find layout
      @layout ||= @page.site.layouts.find { |l| l.path == attribute_named(:layout).cleaned_path }
      raise Nanoc::Errors::UnknownLayoutError.new(attribute_named(:layout)) if @layout.nil?

      @layout
    end

    # Compiles the page representation and writes the result to the disk. This
    # method should not be called directly; please use Nanoc::Compiler#run
    # instead, and pass this page representation's page as its first argument.
    #
    # The page representation will only be compiled if it wasn't compiled
    # before yet. To force recompilation of the page rep, forgetting any
    # progress, set +from_scratch+ to true.
    #
    # +also_layout+:: true if the page rep should also be laid out and
    #                 post-filtered, false if the page rep should only be
    #                 pre-filtered.
    #
    # +even_when_not_outdated+:: true if the page rep should be compiled even
    #                            if it is not outdated, false if not.
    #
    # +from_scratch+:: true if all compilation stages (pre-filter, layout,
    #                  post-filter) should be performed again even if they
    #                  have already been performed, false otherwise.
    def compile(also_layout, even_when_not_outdated, from_scratch)
      # Don't compile if already compiled
      return if @content[also_layout ? :post : :pre] and !from_scratch

      # Skip unless outdated
      unless outdated? or even_when_not_outdated
        if also_layout
          Nanoc::NotificationCenter.post(:compilation_started, self)
          Nanoc::NotificationCenter.post(:compilation_ended,   self)
        end
        return
      end

      # Reset flags
      @compiled = false
      @modified = false
      @created  = false

      # Forget progress if requested
      @content = { :pre => nil, :post => nil } if from_scratch

      # Check for recursive call
      if @page.site.compiler.stack.include?(self)
        @page.site.compiler.stack.push(self)
        raise Nanoc::Errors::RecursiveCompilationError.new
      end

      # Start
      @page.site.compiler.stack.push(self)
      Nanoc::NotificationCenter.post(:compilation_started, self) if also_layout

      # Pre-filter if necesary
      if @content[:pre].nil?
        do_filter(:pre)
      end

      # Post-filter if necessary
      if @content[:post].nil? and also_layout
        do_layout
        do_filter(:post)

        # Update status
        @compiled = true
        unless attribute_named(:skip_output)
          @created  = !File.file?(self.disk_path)
          @modified = @created ? true : File.read(self.disk_path) != @content[:post]
        end

        # Write if necessary
        write unless attribute_named(:skip_output)
      end

      # Stop
      Nanoc::NotificationCenter.post(:compilation_ended, self) if also_layout
      @page.site.compiler.stack.pop
    end

  private

    # Runs the content through the filters in the given stage.
    def do_filter(stage)
      # Get content if necessary
      content = (stage == :pre ? @page.content : @content[:post])

      # Get filters
      check_for_outdated_filters
      filters = attribute_named(stage == :pre ? :filters_pre : :filters_post)

      # Run each filter
      filters.each do |filter_name|
        # Create filter
        klass = Nanoc::Filter.named(filter_name)
        raise Nanoc::Errors::UnknownFilterError.new(filter_name) if klass.nil?
        filter = klass.new(self)

        # Run filter
        Nanoc::NotificationCenter.post(:filtering_started, self, klass.identifier)
        content = filter.run(content)
        # FIXME hacky
        content.force_encoding('utf-8') if content.respond_to?(:'force_encoding')
        Nanoc::NotificationCenter.post(:filtering_ended,   self, klass.identifier)
      end

      # Set content
      @content[stage] = content
    end

    # Runs the content through this rep's layout.
    def do_layout
      # Don't layout if not necessary
      if attribute_named(:layout).nil?
        @content[:post] = @content[:pre]
        return
      end

      # Create filter
      klass = layout.filter_class
      raise Nanoc::Errors::CannotDetermineFilterError.new(layout.path) if klass.nil?
      filter = klass.new(self)

      # Layout
      Nanoc::NotificationCenter.post(:filtering_started, self, klass.identifier)
      @content[:post] = filter.run(layout.content)
      Nanoc::NotificationCenter.post(:filtering_ended,   self, klass.identifier)
    end

    # Writes the compiled content to the disk.
    def write
      # TODO add ruby 1.9 support
      FileUtils.mkdir_p(File.dirname(self.disk_path))
      File.open(self.disk_path, 'w') { |io| io.write(@content[:post]) }
    end

    # Raises an error when the outdated 'filters' attribute is used.
    def check_for_outdated_filters
      unless attribute_named(:filters).nil?
        raise Nanoc::Errors::NoLongerSupportedError.new(
          'The `filters` property is no longer supported; please use ' +
          '`filters_pre` instead.'
        )
      end
    end

  end

end
