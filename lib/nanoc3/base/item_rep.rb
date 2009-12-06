# encoding: utf-8

module Nanoc3

  # A Nanoc3::ItemRep is a single representation (rep) of an item
  # (Nanoc3::Item). An item can have multiple representations. A
  # representation has its own output file. A single item can therefore have
  # multiple output files, each run through a different set of filters with a
  # different layout.
  #
  # An item representation is observable. The following events will be
  # notified:
  #
  # * :compilation_started
  # * :compilation_ended
  # * :filtering_started
  # * :filtering_ended
  #
  # The compilation-related events have one parameters (the item
  # representation); the filtering-related events have two (the item
  # representation, and a symbol containing the filter class name).
  class ItemRep

    # The item (Nanoc3::Item) to which this representation belongs.
    attr_reader   :item

    # This item representation's unique name.
    attr_reader   :name

    # Indicates whether this rep is forced to be dirty by the user.
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

    # Creates a new item representation for the given item.
    #
    # @param [Nanoc3::Item] item The item to which the new representation will
    #   belong.
    #
    # @param [Symbol] name The unique name for the new item representation.
    def initialize(item, name)
      # Set primary attributes
      @item = item
      @name = name

      # Initialize content
      @content = {
        :raw  => @item.raw_content,
        :last => @item.raw_content,
        :pre  => @item.raw_content
      }
      @old_content = nil

      # Reset flags
      @compiled       = false
      @modified       = false
      @created        = false
      @written        = false
      @force_outdated = false
    end

    # @return [Boolean] true if this item rep's output file is outdated and
    # must be regenerated, false otherwise.
    def outdated?
      # Outdated if we don't know
      return true if @item.mtime.nil?

      # Outdated if the dependency tracker says so
      return true if @force_outdated

      # Outdated if compiled file doesn't exist
      return true if self.raw_path.nil?
      return true if !File.file?(self.raw_path)

      # Get compiled mtime
      compiled_mtime = File.stat(self.raw_path).mtime

      # Outdated if file too old
      return true if @item.mtime > compiled_mtime

      # Outdated if layouts outdated
      return true if @item.site.layouts.any? do |l|
        l.mtime.nil? || l.mtime > compiled_mtime
      end

      # Outdated if code outdated
      return true if @item.site.code_snippets.any? do |cs|
        cs.mtime.nil? || cs.mtime > compiled_mtime
      end

      # Outdated if config outdated
      return true if @item.site.config_mtime.nil?
      return true if @item.site.config_mtime > compiled_mtime

      # Outdated if rules outdated
      return true if @item.site.rules_mtime.nil?
      return true if @item.site.rules_mtime > compiled_mtime

      return false
    end

    # @return [Hash] The assignments that should be available when compiling
    #   the content.
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
    # @param [Symbol] snapshot The name of the snapshot from which the content
    #   should be fetched. To get the raw, uncompiled content, use +:raw+.
    #
    # @return [String] The item representation content at the given snapshot.
    def content_at_snapshot(snapshot=:pre)
      Nanoc3::NotificationCenter.post(:visit_started, self.item)
      Nanoc3::NotificationCenter.post(:visit_ended,   self.item)

      puts "*** Attempting to fetch content for #{self.inspect}" if $DEBUG

      raise Nanoc3::Errors::UnmetDependency.new(self) unless compiled?

      @content[snapshot]
    end

    # Runs the item content through the given filter with the given arguments.
    #
    # @param [Symbol] filter_name The name of the filter to run the item
    #   representations' content through.
    #
    # @param [Hash] filter_args The filter arguments that should be passed to
    #   the filter's #run method.
    def filter(filter_name, filter_args={})
      # Create filter
      klass = Nanoc3::Filter.named(filter_name)
      raise Nanoc3::Errors::UnknownFilter.new(filter_name) if klass.nil?
      filter = klass.new(assigns)

      # Run filter
      Nanoc3::NotificationCenter.post(:filtering_started, self, filter_name)
      @content[:last] = filter.run(@content[:last], filter_args)
      Nanoc3::NotificationCenter.post(:filtering_ended, self, filter_name)

      # Create snapshot
      snapshot(@content[:post] ? :post : :pre)
    end

    # Lays out the item using the given layout.
    #
    # @param [String] layout_identifier The identifier of the layout the ite
    #   should be laid out with.
    def layout(layout_identifier)
      # Get layout
      layout ||= @item.site.layouts.find { |l| l.identifier == layout_identifier.cleaned_identifier }
      raise Nanoc3::Errors::UnknownLayout.new(layout_identifier) if layout.nil?

      # Get filter
      filter_name, filter_args  = @item.site.compiler.filter_for_layout(layout)
      raise Nanoc3::Errors::CannotDetermineFilter.new(layout_identifier) if filter_name.nil?

      # Get filter class
      filter_class = Nanoc3::Filter.named(filter_name)
      raise Nanoc3::Errors::UnknownFilter.new(filter_name) if filter_class.nil?

      # Create filter
      filter = filter_class.new(assigns.merge({ :layout => layout }))

      # Create "pre" snapshot
      snapshot(:pre)

      # Layout
      @item.site.compiler.stack.push(layout)
      Nanoc3::NotificationCenter.post(:filtering_started, self, filter_name)
      @content[:last] = filter.run(layout.raw_content, filter_args)
      Nanoc3::NotificationCenter.post(:filtering_ended,   self, filter_name)
      @item.site.compiler.stack.pop

      # Create "post" snapshot
      snapshot(:post)
    end

    # Creates a snapshot of the current compiled item content.
    #
    # @param [Symbol] snapshot_name The name of the snapshot to create.
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
        @old_content = File.read(self.raw_path)
      end

      # Write
      File.open(self.raw_path, 'w') { |io| io.write(@content[:last]) }
      @written = true

      # Check if file was modified
      @modified = File.read(self.raw_path) != @old_content
    end

    def diff
      # Check if old content exists
      if @old_content.nil? or self.raw_path.nil?
        nil
      else
        diff_strings(@old_content, @content[:last])
      end
    end

    def inspect
      "<#{self.class}:0x#{self.object_id.to_s(16)} name=#{self.name} item.identifier=#{self.item.identifier}>"
    end

  private

    def diff_strings(a, b)
      # TODO Rewrite this string-diffing method in pure Ruby. It should not
      # use the "diff" executable, because this will most likely not work on
      # operating systems without it, such as Windows.

      require 'tempfile'
      require 'open3'

      # Create files
      old_file = Tempfile.new('old')
      new_file = Tempfile.new('new')

      # Write files
      old_file.write(a)
      new_file.write(b)

      # Diff
      stdin, stdout, stderr = Open3.popen3('diff', '-u', old_file.path, new_file.path)
      result = stdout.read
      result == '' ? nil : result
    end

  end

end
