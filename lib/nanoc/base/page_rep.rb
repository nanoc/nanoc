module Nanoc

  # TODO document
  class PageRep

    # TODO document
    DEFAULTS = {
      :custom_path  => nil,
      :extension    => 'html',
      :filename     => 'index',
      :filters_pre  => [],
      :filters_post => [],
      :layout       => 'default',
      :skip_output  => false
    }

    # TODO document
    attr_reader   :page

    # TODO document
    attr_accessor :attributes

    # TODO document
    attr_reader   :name

    # TODO document
    def initialize(page, attributes, name)
      # Set primary attributes
      @page           = page
      @attributes     = attributes
      @name           = name

      # Get page content from page
      @content        = { :pre => page.content(:raw), :post => nil }

      # Not modified, not created by default
      @modified       = false
      @created        = false

      # Reset flags
      @filtered_pre   = false
      @laid_out       = false
      @filtered_post  = false
      @written        = false
    end

    # TODO document
    def to_proxy
      @proxy ||= PageRepProxy.new(self)
    end

    # TODO document
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

    # TODO document
    def disk_path
      @disk_path ||= @page.site.router.disk_path_for(self)
    end

    # TODO document
    def web_path
      @web_path ||= @page.site.router.web_path_for(self)
    end

    # TODO document
    def attribute_named(name)
      return @attributes[name] if @attributes.has_key?(name)
      return @page.attribute_named(name)
    end

    # TODO document
    def content(stage=:pre)
      compile(false) if stage == :pre  and !@filtered_pre
      compile(true)  if stage == :post and !@filtered_post
      @content[stage]
    end

    # TODO document
    def layout
      # Check whether layout is present
      return nil if attribute_named(:layout).nil?

      # Find layout
      @layout ||= @page.site.layouts.find { |l| l.path == attribute_named(:layout).cleaned_path }
      raise Nanoc::Errors::UnknownLayoutError.new(attribute_named(:layout)) if @layout.nil?

      @layout
    end

    # TODO document
    def compile(also_layout=true)
      @modified = false

      # Check for recursive call
      if @page.site.compiler.stack.include?(self)
        @page.site.compiler.stack.push(self)
        raise Nanoc::Errors::RecursiveCompilationError.new 
      end

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
    end

  private

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
        filter = klass.new(self.to_proxy, @page.site)

        # Run filter
        @content[stage] = filter.run(@content[stage])
      end
    end

    def layout!
      # Don't layout if not necessary
      if attribute_named(:layout).nil?
        @content[:post] = @content[:pre]
        return
      end

      # Create filter
      klass = layout.filter_class
      raise Nanoc::Errors::CannotDetermineFilterError(layout.path) if klass.nil?
      filter = klass.new(self.to_proxy, @page.site)

      # Layout
      @content[:post] = filter.run(layout.content)
    end

  end

end
