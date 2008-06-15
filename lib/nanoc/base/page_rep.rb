require 'observer'

module Nanoc

  # A Nanoc::PageRep is a single representation (rep) of a page (Nanoc::Page).
  # A page can have multiple representations. A representation has its own
  # attributes and its own output file. A single page can therefore have
  # multiple output files, each run through a different set of filters with a
  # different layout.
  #
  # A page representation is observable. Events will be notified through the
  # 'update' method (as specified by Observable) with the page representation
  # as its first argument, followed by a symbol describing the event (listed
  # in chronological order):
  #
  # * :compile_start
  # * :compile_end
  class PageRep

    include Observable

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
      @content        = { :pre => page.content, :post => nil }

      # Not modified, not created by default
      @modified       = false
      @created        = false

      # Reset flags
      @filtered_pre   = false
      @laid_out       = false
      @filtered_post  = false
      @written        = false
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

    # Returns true if this page rep's output file is outdated and must be
    # regenerated, false otherwise.
    def outdated?
      # Outdated if compiled file doesn't exist
      return true if !File.file?(disk_path)

      # Get compiled mtime
      compiled_mtime = File.stat(disk_path).mtime

      # Outdated if file too old
      return true if @page.mtime > compiled_mtime

      # Outdated if dependencies outdated
      return true if @page.site.layouts.any? { |l| l.mtime and l.mtime > compiled_mtime }
      return true if @page.site.page_defaults.mtime and @page.site.page_defaults.mtime > compiled_mtime
      return true if @page.site.code.mtime and @page.site.code.mtime > compiled_mtime

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
    # 2. The attributes of this page representation's page (but only if this
    #    is the default representation);
    # 3. The page defaults' representation corresponding to this page
    #    representation;
    # 4. The page defaults in general (but only if this is the default page
    #    representation);
    # 5. The hardcoded page defaults, if everything else fails.
    def attribute_named(name)
      # Check in here
      return @attributes[name] if @attributes.has_key?(name)

      # Check in page
      if @name == :default
        return @page.attributes[name] if @page.attributes.has_key?(name)
      end

      # Check in page defaults' page rep
      page_default_reps = @page.site.page_defaults.attributes[:reps] || {}
      page_default_rep  = page_default_reps[@name] || {}
      return page_default_rep[name] if page_default_rep.has_key?(name)

      # Check in site defaults (global)
      if @name == :default
        page_defaults_attrs = @page.site.page_defaults.attributes
        return page_defaults_attrs[name] if page_defaults_attrs.has_key?(name)
      end

      # Check in hardcoded defaults
      return Nanoc::Page::DEFAULTS[name]
    end

    # Returns the page representation content at the given stage.
    #
    # +stage+:: The stage at which the content should be fetched. Can be
    #           either +:pre+ or +:post+. To get the raw, uncompiled content,
    #           use Nanoc::Page#content.
    def content(stage=:pre)
      compile(false) if stage == :pre  and !@filtered_pre
      compile(true)  if stage == :post and !@filtered_post
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

    # Compiles the page representation. This will run the pre-filters, layout
    # the page representation, run the post-filters, and write the resulting
    # page rep to disk (unless +skip_output+ is set).
    #
    # +also_layout+:: true if the page representation should be laid out (and
    #                 post-filtered), and false if not.
    def compile(also_layout=true)
      @modified = false

      # Check for recursive call
      if @page.site.compiler.stack.include?(self)
        @page.site.compiler.stack.push(self)
        raise Nanoc::Errors::RecursiveCompilationError.new 
      end

      notify(:compile_start)
      @page.site.compiler.stack.push(self)

      # Filter pre
      unless @filtered_pre
        filter!(:pre)
        @filtered_pre = true
      end

      # Layout
      if !@laid_out and also_layout
        layout!
        @laid_out = true
      end

      # Filter post
      if !@filtered_post and also_layout
        filter!(:post)
        @filtered_post = true
      end

      # Write
      if !@written and also_layout
        # Check status
        @created  = !File.file?(self.disk_path)
        @modified = @created ? true : File.read(self.disk_path) != @content[:post]

        # Write
        unless attribute_named(:skip_output)
          FileUtils.mkdir_p(File.dirname(self.disk_path))
          File.open(self.disk_path, 'w') { |io| io.write(@content[:post]) }
        end

        # Done
        @written = true
      end

      @page.site.compiler.stack.pop
      notify(:compile_end)
    end

  private

    # Runs the content through the filters in the given stage.
    def filter!(stage)
      # Get filters
      unless attribute_named(:filters).nil?
        raise Nanoc::Errors::NoLongerSupportedError.new(
          'The `filters` property is no longer supported; please use ' +
          '`filters_pre` instead.'
        )
      end
      filters = attribute_named(stage == :pre ? :filters_pre : :filters_post)

      # Run each filter
      filters.each do |filter_name|
        # Create filter
        klass = PluginManager.instance.filter(filter_name.to_sym)
        raise Nanoc::Errors::UnknownFilterError.new(filter_name) if klass.nil?
        filter = klass.new(:page, self.to_proxy, @page.to_proxy, @page.site)

        # Run filter
        @content[stage] = filter.run(@content[stage])
      end
    end

    # Runs the content through this rep's layout.
    def layout!
      # Don't layout if not necessary
      if attribute_named(:layout).nil?
        @content[:post] = @content[:pre]
        return
      end

      # Create filter
      klass = layout.filter_class
      raise Nanoc::Errors::CannotDetermineFilterError(layout.path) if klass.nil?
      filter = klass.new(:page, self.to_proxy, @page.to_proxy, @page.site)

      # Layout
      @content[:post] = filter.run(layout.content)
    end

    def notify(event)
      changed
      notify_observers(self, event)
    end

  end

end
