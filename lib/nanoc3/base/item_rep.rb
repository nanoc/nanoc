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
      :not_enough_data => 'Not enough data is present to correctly determine whether the item is outdated.',
      :forced => 'All items are recompiled because of a `--force` flag given to the compilation command.',
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
    #   of the `--force` commandline option); false otherwise
    attr_accessor :force_outdated

    # @return [Boolean] true if this rep is currently binary; false otherwise
    attr_reader :binary
    alias_method :binary?, :binary

    # @return [Boolean] true if this rep’s output file has changed since the
    #   last time it was compiled; false otherwise
    attr_accessor :modified
    alias_method :modified?, :modified

    # @return [Boolean] true if this rep’s output file was created during the
    #   current or last compilation session; false otherwise
    attr_accessor :created
    alias_method :created?, :created

    # @return [Boolean] true if this representation has already been compiled
    #   during the current or last compilation session; false otherwise
    attr_accessor :compiled
    alias_method :compiled?, :compiled

    # @return [Hash<Symbol,String>] A hash containing the raw paths (paths
    #   including the path to the output directory and the filename) for all
    #   snapshots. The keys correspond with the snapshot names, and the values
    #   with the path.
    attr_accessor :raw_paths

    # @return [Hash<Symbol,String>] A hash containing the paths for all
    #   snapshots. The keys correspond with the snapshot names, and the values
    #   with the path.
    attr_accessor :paths

    # @return [Hash<Symbol,String>] A hash containing the content at all
    #   snapshots. The keys correspond with the snapshot names, and the
    #   values with the content.
    attr_accessor :content

    # Creates a new item representation for the given item.
    #
    # @param [Nanoc3::Item] item The item to which the new representation will
    #   belong.
    #
    # @param [Symbol] name The unique name for the new item representation.
    def initialize(item, name)
      # Set primary attributes
      @item   = item
      @name   = name

      # Set binary
      @binary = @item.binary?

      # Initialize content and filenames and paths
      @raw_paths   = {}
      @paths       = {}
      @old_content = nil
      initialize_content

      # Reset flags
      @compiled       = false
      @modified       = false
      @created        = false
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
        # Outdated if we’re compiling with --force
        return :forced if @force_outdated

        # Outdated if checksums are missing
        if !@item.old_checksum || !@item.new_checksum
          return :not_enough_data
        end

        # Outdated if compiled file doesn't exist (yet)
        return :not_written if self.raw_path && !File.file?(self.raw_path)

        # Outdated if file too old
        if @item.old_checksum != @item.new_checksum
          return :source_modified
        end

        # Outdated if layouts outdated
        return :layouts_outdated if @item.site.layouts.any? do |l|
          !l.old_checksum || !l.new_checksum || l.new_checksum != l.old_checksum
        end

        # Outdated if code outdated
        return :code_outdated if @item.site.code_snippets.any? do |cs|
          !cs.old_checksum || !cs.new_checksum || cs.new_checksum != cs.old_checksum
        end

        # Outdated if config outdated
        if !@item.site.old_config_checksum || !@item.site.new_config_checksum || @item.site.old_config_checksum != @item.site.new_config_checksum
          return :config_outdated
        end

        # Outdated if rules modified
        if !@item.site.old_rules_checksum || !@item.site.new_rules_checksum || @item.site.old_rules_checksum != @item.site.new_rules_checksum
          return :rules_outdated
        end

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
    #   must be regenerated, false otherwise
    def outdated?
      !outdatedness_reason.nil?
    end

    # @return [Hash] The assignments that should be available when compiling
    #   the content.
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
    #   fetch the compiled content. By default, the returned compiled content
    #   will be the content compiled right before the first layout call (if
    #   any).
    #
    # @return [String] The compiled content at the given snapshot (or the
    #   default snapshot if no snapshot is specified)
    def compiled_content(params={})
      # Notify
      Nanoc3::NotificationCenter.post(:visit_started, self.item)
      Nanoc3::NotificationCenter.post(:visit_ended,   self.item)

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

    # Returns the item rep’s raw path. It includes the path to the output
    # directory and the full filename.
    #
    # @option params [Symbol] :snapshot (:last) The snapshot for which the
    #   path should be returned
    #
    # @return [String] The item rep’s path
    def raw_path(params={})
      snapshot_name = params[:snapshot] || :last
      @raw_paths[snapshot_name]
    end

    # Returns the item rep’s path, as used when being linked to. It starts
    # with a slash and it is relative to the output directory. It does not
    # include the path to the output directory. It will not include the
    # filename if the filename is an index filename.
    #
    # @option params [Symbol] :snapshot (:last) The snapshot for which the
    #   path should be returned
    #
    # @return [String] The item rep’s path
    def path(params={})
      snapshot_name = params[:snapshot] || :last
      @paths[snapshot_name]
    end

    # @deprecated Modify the {#raw_paths} attribute instead
    def raw_path=(raw_path)
      raw_paths[:last] = raw_path
    end

    # @deprecated Modify the {#paths} attribute instead
    def path=(path)
      paths[:last] = path
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
    #   representations' content through
    #
    # @param [Hash] filter_args The filter arguments that should be passed to
    #   the filter's #run method
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
    #   should be laid out with
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
      # Create snapshot
       @content[snapshot_name] = @content[:last] unless self.binary?

      # Write
      write(snapshot_name)
    end

    # Writes the item rep's compiled content to the rep's output file.
    #
    # This method should not be called directly, even in a compilation block;
    # the compiler is responsible for calling this method.
    #
    # @param [String, nil] raw_path The raw path to write the compiled rep to.
    #   If nil, the default raw path will be used.
    #
    # @return [void]
    def write(snapshot=:last)
      # Get raw path
      raw_path = self.raw_path(:snapshot => snapshot)
      return if raw_path.nil?

      # Create parent directory
      FileUtils.mkdir_p(File.dirname(raw_path))

      # Check if file will be created
      @created = !File.file?(raw_path)

      if self.binary?
        # Calculate hash of old content
        if File.file?(raw_path)
          hash_old = Nanoc3::Checksummer.checksum_for(raw_path)
          size_old = File.size(raw_path)
        end

        # Copy
        FileUtils.cp(@filenames[:last], raw_path)

        # Check if file was modified
        size_new = File.size(raw_path)
        hash_new = Nanoc3::Checksummer.checksum_for(raw_path) if size_old == size_new
        @modified = (size_old != size_new || hash_old != hash_new)
      else
        # Remember old content
        if File.file?(raw_path)
          @old_content = File.read(raw_path)
        end

        # Write
        File.open(raw_path, 'w') { |io| io.write(@content[:last]) }

        # Generate diff
        generate_diff

        # Check if file was modified
        @modified = File.read(raw_path) != @old_content
      end

      # Notify
      Nanoc3::NotificationCenter.post(:rep_written, self, raw_path, @created, @updated)
    end

    # Creates and returns a diff between the compiled content before the
    # current compilation session and the content compiled in the current
    # compilation session.
    #
    # @return [String, nil] The difference between the old and new compiled
    #   content in `diff(1)` format, or nil if there is no previous compiled
    #   content
    def diff
      if self.binary?
        nil
      else
         @diff_thread.join if @diff_thread
        @diff
      end
    end

    # @deprecated
    def written
      raise NotImplementedError, "Nanoc3::ItemRep#written is no longer implemented"
    end

    # @deprecated
    def written?
      raise NotImplementedError, "Nanoc3::ItemRep#written is no longer implemented"
    end

    def inspect
      "<#{self.class}:0x#{self.object_id.to_s(16)} name=#{self.name} binary=#{self.binary?} raw_path=#{self.raw_path} item.identifier=#{self.item.identifier}>"
    end

  private

    def initialize_content
      # Initialize content and filenames
      if self.binary?
        @filenames = { :last => @item.raw_filename }
        @content   = {}
      else
        @content   = { :last => @item.raw_content }
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
      raise Nanoc3::Errors::CannotDetermineFilter.new(layout_identifier) if filter_name.nil?

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

  end

end
