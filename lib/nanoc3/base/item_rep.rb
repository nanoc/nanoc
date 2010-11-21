# encoding: utf-8

module Nanoc3

  # A single representation (rep) of an item ({Nanoc3::Item}). An item can
  # have multiple representations. A representation has its own output file.
  # A single item can therefore have multiple output files, each run through
  # a different set of filters with a different layout.
  #
  # An item representation is observable. The following events will be
  # notified:
  #
  # * `:compilation_started`
  # * `:compilation_ended`
  # * `:filtering_started`
  # * `:filtering_ended`
  #
  # The compilation-related events have one parameters (the item
  # representation); the filtering-related events have two (the item
  # representation, and a symbol containing the filter class name).
  class ItemRep

    # The descriptive strings for each outdatedness reason. This hash is used
    # by the {#outdatedness_reason} method.
    OUTDATEDNESS_REASON_DESCRIPTIONS = {
      :no_mtime => 'No file modification time is available.',
      :forced => 'All pages are recompiled because of a `--force` flag given to the compilation command.',
      :no_raw_path => 'The routing rules do not specify a path where this item should be written to, i.e. the item representation will never be written to the output directory.',
      :not_written => 'This item representation has not yet been written to the output directory (but it does have a path).',
      :source_modified => 'The source file of this item has been modified since the last time this item representation was compiled.',
      :layouts_outdated => 'The source of one or more layouts has been modified since the last time this item representation was compiled.',
      :code_outdated => 'The code snippets in the `lib/` directory have been modified since the last time this item representation was compiled.',
      :config_outdated => 'The site configuration has been modified since the last time this item representation was compiled.',
      :rules_outdated => 'The rules file has been modified since the last time this item representation was compiled.',
    }

    # @return [Nanoc3::Item] The item to which this rep belongs
    attr_reader   :item

    # @return [Symbol] The representation's unique name
    attr_reader   :name

    # @return [Boolean] true if this rep is forced to be dirty (e.g. because
    # of the `--force` commandline option); false otherwise
    attr_accessor :force_outdated

    # @return [Boolean] true if this rep is currently binary; false otherwise
    attr_reader :binary
    alias_method :binary?, :binary

    # @return [Boolean] true if this rep’s output file has changed since the
    # last time it was compiled; false otherwise
    attr_accessor :modified
    alias_method :modified?, :modified

    # @return [Boolean] true if this rep’s output file was created during the
    # current or last compilation session; false otherwise
    attr_accessor :created
    alias_method :created?, :created

    # @return [Boolean] true if this representation has already been compiled
    # during the current or last compilation session; false otherwise
    attr_accessor :compiled
    alias_method :compiled?, :compiled

    # @return [Boolean] true if this representation’s compiled content has
    # been written during the current or last compilation session; false
    # otherwise
    attr_reader :written
    alias_method :written?, :written

    # @return [String] The item rep's path, as used when being linked to. It
    # starts with a slash and it is relative to the output directory. It does
    # not include the path to the output directory. It will not include the
    # filename if the filename is an index filename.
    attr_accessor :path

    # @return [String] The item rep's raw path. It is relative to the current
    # working directory and includes the path to the output directory. It also
    # includes the filename, even if it is an index filename.
    attr_accessor :raw_path

    # Creates a new item representation for the given item.
    #
    # @param [Nanoc3::Item] item The item to which the new representation will
    # belong.
    #
    # @param [Symbol] name The unique name for the new item representation.
    def initialize(item, name)
      # Set primary attributes
      @item   = item
      @name   = name

      # Set binary
      @binary = @item.binary?

      # Initialize content and filenames
      initialize_content
      @old_content = nil

      # Reset flags
      @compiled       = false
      @modified       = false
      @created        = false
      @written        = false
      @force_outdated = false
    end

    # Calculates the reason why this item representation is outdated. The
    # output will be a hash with a `:type` key, containing the reason why the
    # item is outdated in the form of a symbol, and a `:description` key,
    # containing a descriptive string that can be printed if necessary.
    #
    # For documentation on the types that this method can return, check the
    # {OUTDATEDNESS_REASON_DESCRIPTIONS} hash in this class.
    #
    # @return [Hash, nil] A hash containing the reason why this item rep is
    #   outdated, both in the form of a symbol and as a descriptive string, or
    #   nil if the item representation is not outdated.
    def outdatedness_reason
      # Get reason symbol
      reason = lambda do
        # Outdated if we don't know
        return :no_mtime if @item.mtime.nil?

        # Outdated if the dependency tracker says so
        return :forced if @force_outdated

        # Outdated if compiled file doesn't exist (yet)
        return :no_raw_path if self.raw_path.nil?
        return :not_written if !File.file?(self.raw_path)

        # Get compiled mtime
        compiled_mtime = File.stat(self.raw_path).mtime

        # Outdated if file too old
        return :source_modified if @item.mtime > compiled_mtime

        # Outdated if layouts outdated
        return :layouts_outdated if @item.site.layouts.any? do |l|
          l.mtime.nil? || l.mtime > compiled_mtime
        end

        # Outdated if code outdated
        return :code_outdated if @item.site.code_snippets.any? do |cs|
          cs.mtime.nil? || cs.mtime > compiled_mtime
        end

        # Outdated if config outdated
        return :config_outdated if @item.site.config_mtime.nil?
        return :config_outdated if @item.site.config_mtime > compiled_mtime

        # Outdated if rules outdated
        return :rules_outdated if @item.site.rules_mtime.nil?
        return :rules_outdated if @item.site.rules_mtime > compiled_mtime

        return nil
      end[]

      # Build reason symbol and description
      if reason.nil?
        nil
      else
        {
          :type        => reason,
          :description => OUTDATEDNESS_REASON_DESCRIPTIONS[reason]
        }
      end
    end

    # @return [Boolean] true if this item rep's output file is outdated and
    # must be regenerated, false otherwise
    def outdated?
      !outdatedness_reason.nil?
    end

    # @return [Hash] The assignments that should be available when compiling
    # the content.
    def assigns
      if self.binary?
        content_or_filename_assigns = { :filename => @filenames[:last] }
      else
        content_or_filename_assigns = { :content => @content[:last] }
      end

      content_or_filename_assigns.merge({
        :item       => self.item,
        :item_rep   => self,
        :items      => self.item.site.items,
        :layouts    => self.item.site.layouts,
        :config     => self.item.site.config,
        :site       => self.item.site
      })
    end

    # Returns the compiled content from a given snapshot.
    #
    # @option params [String] :snapshot The name of the snapshot from which to
    # fetch the compiled content. By default, the returned compiled content
    # will be the content compiled right before the first layout call (if
    # any).
    #
    # @return [String] The compiled content at the given snapshot (or the
    # default snapshot if no snapshot is specified)
    def compiled_content(params={})
      # Notify
      Nanoc3::NotificationCenter.post(:visit_started, self.item)
      Nanoc3::NotificationCenter.post(:visit_ended,   self.item)

      # Debug
      puts "*** Attempting to fetch content for #{self.inspect}" if $DEBUG

      # Require compilation
      raise Nanoc3::Errors::UnmetDependency.new(self) unless compiled?

      # Get name of last pre-layout snapshot
      snapshot_name = params[:snapshot]
      if @content[:pre]
        snapshot_name ||= :pre
      else
        snapshot_name ||= :last
      end

      # Check presence of snapshot
      if @content[snapshot_name].nil?
        warn "WARNING: The “#{self.item.identifier}” item (rep “#{self.name}”) does not have the requested snapshot named #{snapshot_name.inspect}.\n\n* Make sure that you are requesting the correct snapshot.\n* It is not possible to request the compiled content of a binary item representation; if this item is marked as binary even though you believe it should be textual, you may need to add the extension of this item to the site configuration’s `text_extensions` array.".make_compatible_with_env
      end

      # Get content
      @content[snapshot_name]
    end

    # @deprecated Use {Nanoc3::ItemRep#compiled_content} instead.
    def content_at_snapshot(snapshot=:pre)
      compiled_content(:snapshot => snapshot)
    end

    # Resets the compilation progress for this item representation. This is
    # necessary when an unmet dependency is detected during compilation.
    # This method should probably not be called directly.
    #
    # @return [void]
    def forget_progress
      initialize_content
    end

    # Runs the item content through the given filter with the given arguments.
    # This method will replace the content of the `:last` snapshot with the
    # filtered content of the last snapshot.
    #
    # This method is supposed to be called only in a compilation rule block
    # (see {Nanoc3::CompilerDSL#compile}).
    #
    # @param [Symbol] filter_name The name of the filter to run the item
    # representations' content through
    #
    # @param [Hash] filter_args The filter arguments that should be passed to
    # the filter's #run method
    #
    # @return [void]
    def filter(filter_name, filter_args={})
      # Get filter class
      klass = filter_named(filter_name)
      raise Nanoc3::Errors::UnknownFilter.new(filter_name) if klass.nil?

      # Check whether filter can be applied
      if klass.from_binary? && !self.binary?
        raise Nanoc3::Errors::CannotUseBinaryFilter.new(self, klass)
      elsif !klass.from_binary? && self.binary?
        raise Nanoc3::Errors::CannotUseTextualFilter.new(self, klass)
      end

      # Create filter
      filter = klass.new(assigns)

      # Run filter
      Nanoc3::NotificationCenter.post(:filtering_started, self, filter_name)
      source = self.binary? ? @filenames[:last] : @content[:last]
      result = filter.run(source, filter_args)
      if klass.to_binary?
        @filenames[:last] = filter.output_filename
      else
        @content[:last] = result
      end
      @binary = klass.to_binary?
      Nanoc3::NotificationCenter.post(:filtering_ended, self, filter_name)

      # Check whether file was written
      if self.binary? && !File.file?(filter.output_filename)
        raise RuntimeError,
          "The #{filter_name.inspect} filter did not write anything to the required output file, #{filter.output_filename}."
      end

      # Create snapshot
      snapshot(@content[:post] ? :post : :pre) unless self.binary?
    end

    # Lays out the item using the given layout. This method will replace the
    # content of the `:last` snapshot with the laid out content of the last
    # snapshot.
    #
    # This method is supposed to be called only in a compilation rule block
    # (see {Nanoc3::CompilerDSL#compile}).
    #
    # @param [String] layout_identifier The identifier of the layout the item
    # should be laid out with
    #
    # @return [void]
    def layout(layout_identifier)
      # Check whether item can be laid out
      raise Nanoc3::Errors::CannotLayoutBinaryItem.new(self) if self.binary?

      # Create "pre" snapshot
      snapshot(:pre) unless @content[:pre]

      # Create filter
      layout = layout_with_identifier(layout_identifier)
      filter, filter_name, filter_args = filter_for_layout(layout)

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
    # @param [Symbol] snapshot_name The name of the snapshot to create
    #
    # @return [void]
    def snapshot(snapshot_name)
      target = self.binary? ? @filenames : @content
      target[snapshot_name] = target[:last]
    end

    # Writes the item rep's compiled content to the rep's output file.
    #
    # This method should not be called directly, even in a compilation block;
    # the compiler is responsible for calling this method.
    #
    # @return [void]
    def write
      # Create parent directory
      FileUtils.mkdir_p(File.dirname(self.raw_path))

      # Check if file will be created
      @created = !File.file?(self.raw_path)

      if self.binary?
        # Calculate hash of old content
        if File.file?(self.raw_path)
          hash_old = hash_for_file(self.raw_path)
          size_old = File.size(self.raw_path)
        end
        size_new = File.size(@filenames[:last])
        hash_new = hash_for_file(@filenames[:last]) if size_old == size_new

        # Check if file was modified
        @modified = (size_old != size_new || hash_old != hash_new)

        # Copy
        if @modified
          FileUtils.cp(@filenames[:last], self.raw_path)
        end
        @written = true
      else
        # Remember old content
        if File.file?(self.raw_path)
          @old_content = File.read(self.raw_path)
        end

        # Write
        new_content = @content[:last]
        if @old_content != new_content
          File.open(self.raw_path, 'w') { |io| io.write(new_content) }
        end
        @written = true

        # Generate diff
        generate_diff

        # Check if file was modified
        @modified = File.read(self.raw_path) != @old_content
      end
    end

    # Creates and returns a diff between the compiled content before the
    # current compilation session and the content compiled in the current
    # compilation session.
    #
    # @return [String, nil] The difference between the old and new compiled
    # content in `diff(1)` format, or nil if there is no previous compiled
    # content
    def diff
      if self.binary?
        nil
      else
         @diff_thread.join if @diff_thread
        @diff
      end
    end

    def inspect
      "<#{self.class}:0x#{self.object_id.to_s(16)} name=#{self.name} binary=#{self.binary?} raw_path=#{self.raw_path} item.identifier=#{self.item.identifier}>"
    end

  private

    def initialize_content
      # Initialize content and filenames
      if self.binary?
        @filenames = {
          :raw  => @item.raw_filename,
          :last => @item.raw_filename
        }
        @content = {}
      else
        @content = {
          :raw  => @item.raw_content,
          :last => @item.raw_content,
          :pre  => @item.raw_content
        }
        @filenames = {}
      end
    end

    def filter_named(name)
      Nanoc3::Filter.named(name)
    end

    def layout_with_identifier(layout_identifier)
      layout ||= @item.site.layouts.find { |l| l.identifier == layout_identifier.cleaned_identifier }
      raise Nanoc3::Errors::UnknownLayout.new(layout_identifier) if layout.nil?
      layout
    end

    def filter_for_layout(layout)
      # Get filter name and args
      filter_name, filter_args  = @item.site.compiler.filter_for_layout(layout)
      raise Nanoc3::Errors::CannotDetermineFilter.new(layout.identifier) if filter_name.nil?

      # Get filter class
      filter_class = Nanoc3::Filter.named(filter_name)
      raise Nanoc3::Errors::UnknownFilter.new(filter_name) if filter_class.nil?

      # Create filter
      filter = filter_class.new(assigns.merge({ :layout => layout }))

      # Done
      [ filter, filter_name, filter_args ]
    end

    def generate_diff
      if @old_content.nil? || self.raw_path.nil? || !@item.site.config[:enable_output_diff]
        @diff = nil
      else
        @diff_thread = Thread.new do
          @diff = diff_strings(@old_content, @content[:last])
          sleep 2
          @diff_thread = nil
        end
      end
    end

    def diff_strings(a, b)
      require 'tempfile'
      require 'open3'

      # Create files
      Tempfile.open('old') do |old_file|
        Tempfile.open('new') do |new_file|
          # Write files
          old_file.write(a)
          new_file.write(b)

          # Diff
          cmd = [ 'diff', '-u', old_file.path, new_file.path ]
          Open3.popen3(*cmd) do |stdin, stdout, stderr|
            result = stdout.read
            return (result == '' ? nil : result)
          end
        end
      end
    rescue Errno::ENOENT
      warn 'Failed to run `diff`, so no diff with the previously compiled ' \
           'content will be available.'
      nil
    end

    # Returns a hash of the given filename
    def hash_for_file(filename)
      digest = Digest::SHA1.new
      File.open(filename, 'r') do |io|
        until io.eof
          data = io.readpartial(2**10)
          digest.update(data)
        end
      end
      digest.hexdigest
    end

  end

end
