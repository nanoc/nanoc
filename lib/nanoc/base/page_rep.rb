module Nanoc

  class PageRep < Nanoc::ItemRep

    # For compatibility
    alias_method :page, :item

    # Returns the type of this object.
    def type
      :page_rep
    end

    # Returns true if this page rep's output file is outdated and must be
    # regenerated, false otherwise.
    def outdated?
      # Make super run a few checks
      return true if super

      # Get compiled mtime
      compiled_mtime = File.stat(disk_path).mtime if !attribute_named(:skip_output)

      # Outdated if page defaults outdated
      return true if @item.site.page_defaults.mtime.nil?
      return true if !attribute_named(:skip_output) && @item.site.page_defaults.mtime > compiled_mtime

      return false
    end

    # Returns the attribute with the given name. This method will look in
    # several places for the requested attribute:
    #
    # 1. This item representation's attributes;
    # 2. The attributes of this item representation's item;
    # 3. The item defaults' representation corresponding to this item
    #    representation;
    # 4. The item defaults in general;
    # 5. The hardcoded item defaults, if everything else fails.
    def attribute_named(name)
      super(name, @item.site.page_defaults, Nanoc::Page::DEFAULTS)
    end

    # Returns the page representation content at the given stage.
    #
    # +stage+:: The stage at which the content should be fetched. Can be
    #           either +:pre+ or +:post+. To get the raw, uncompiled content,
    #           use Nanoc::Page#content.
    def content(stage = :pre, even_when_not_outdated = true, from_scratch = false)
      Nanoc::NotificationCenter.post(:visit_started, self)
      compile(stage == :post, even_when_not_outdated, from_scratch)
      Nanoc::NotificationCenter.post(:visit_ended,   self)

      @content[stage]
    end

    # Returns the layout used for this page representation.
    def layout
      # Check whether layout is present
      return nil if attribute_named(:layout).nil?

      # Find layout
      @layout ||= @item.site.layouts.find { |l| l.path == attribute_named(:layout).cleaned_path }
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
      @content = {} if from_scratch

      # Check for recursive call
      if @item.site.compiler.stack.include?(self)
        @item.site.compiler.stack.push(self)
        raise Nanoc::Errors::RecursiveCompilationError.new
      end

      # Start
      @item.site.compiler.stack.push(self)
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
      @item.site.compiler.stack.pop
    end

  private

    # Runs the content through the filters in the given stage.
    def do_filter(stage)
      # Get filters
      filters = attribute_named(stage == :pre ? :filters_pre : :filters_post)

      # Create raw and last snapshots if necessary
      # FIXME probably shouldn't belong here
      @content[:raw]  ||= @item.content
      @content[:last] ||= @content[:raw]

      # Run each filter
      filters.each do |raw_filter|
        # Get filter arguments, if any
        if raw_filter.is_a?(String)
          filter_name = raw_filter
          filter_args = {}
        else
          filter_name = raw_filter['name']
          filter_args = raw_filter['args'] || {}
        end

        # Filter
        filter!(filter_name, filter_args)
      end

      # Set content
      @content[stage] = @content[:last]
    end

    # Runs the content through this rep's layout.
    def do_layout
      # Don't layout if not necessary
      if attribute_named(:layout).nil?
        @content[:post] = @content[:pre]
        return
      end

      # Layout
      layout!(attribute_named(:layout))

      # Set content
      @content[:post] = @content[:last]
    end

    # Writes the compiled content to the disk.
    def write
      # TODO add ruby 1.9 support
      FileUtils.mkdir_p(File.dirname(self.disk_path))
      File.open(self.disk_path, 'w') { |io| io.write(@content[:post]) }
    end

  end

end
