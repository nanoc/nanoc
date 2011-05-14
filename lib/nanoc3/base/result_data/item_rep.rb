# encoding: utf-8

module Nanoc3

  # A single representation (rep) of an item ({Nanoc3::Item}). An item can
  # have multiple representations. A representation has its own output file.
  # A single item can therefore have multiple output files, each run through
  # a different set of filters with a different layout.
  class ItemRep

    # Contains all deprecated methods. Mixed into {Nanoc3::ItemRep}.
    module Deprecated

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

      # @deprecated
      def created
        raise NotImplementedError, "Nanoc3::ItemRep#created is no longer implemented"
      end

      # @deprecated
      def created?
        raise NotImplementedError, "Nanoc3::ItemRep#created? is no longer implemented"
      end

      # @deprecated
      def modified
        raise NotImplementedError, "Nanoc3::ItemRep#modified is no longer implemented"
      end

      # @deprecated
      def modified?
        raise NotImplementedError, "Nanoc3::ItemRep#modified? is no longer implemented"
      end

      # @deprecated
      def written
        raise NotImplementedError, "Nanoc3::ItemRep#written is no longer implemented"
      end

      # @deprecated
      def written?
        raise NotImplementedError, "Nanoc3::ItemRep#written? is no longer implemented"
      end

    end

    # Contains all private methods. Mixed into {Nanoc3::ItemRep}.
    module Private

      # @return [Hash] A hash containing the assigns that will be used in the
      #   next filter or layout operation. The keys (symbols) will be made
      #   available during the next operation.
      attr_accessor :assigns

      # @return [Boolean] true if this representation has already been
      #   compiled during the current or last compilation session; false
      #   otherwise
      #
      # @api private
      attr_accessor :compiled
      alias_method :compiled?, :compiled

      # @return [Hash<Symbol,String>] A hash containing the raw paths (paths
      #   including the path to the output directory and the filename) for all
      #   snapshots. The keys correspond with the snapshot names, and the
      #   values with the path.
      #
      # @api private
      attr_accessor :raw_paths

      # @return [Hash<Symbol,String>] A hash containing the paths for all
      #   snapshots. The keys correspond with the snapshot names, and the
      #   values with the path.
      #
      # @api private
      attr_accessor :paths

      # @return [Hash<Symbol,String>] A hash containing the paths to the
      #   temporary _files_ that filters write binary content to. This is only
      #   used when the item representation is binary. The keys correspond
      #   with the snapshot names, and the values with the filename. When
      #   writing the item representation, the file corresponding with the
      #   requested snapshot (usually `:last`) will be copied from
      #   `filenames[snapshot]` to `raw_paths[snapshot]`.
      #
      # @api private
      attr_reader :temporary_filenames

      # @return [Hash<Symbol,String>] A hash containing the content at all
      #   snapshots. The keys correspond with the snapshot names, and the
      #   values with the content.
      #
      # @api private
      attr_accessor :content

      # Writes the item rep's compiled content to the rep's output file.
      #
      # This method will send two notifications: one before writing the item
      # representation, and one after. These notifications can be used for
      # generating diffs, for example.
      #
      # @api private
      #
      # @param [String, nil] raw_path The raw path to write the compiled rep
      #   to. If nil, the default raw path will be used.
      #
      # @return [void]
      def write(snapshot=:last)
        # Get raw path
        raw_path = self.raw_path(:snapshot => snapshot)
        return if raw_path.nil?

        # Create parent directory
        FileUtils.mkdir_p(File.dirname(raw_path))

        # Check if file will be created
        is_created = !File.file?(raw_path)

        # Calculate characteristics of old content
        if File.file?(raw_path)
          hash_old = Nanoc3::Checksummer.checksum_for_file(raw_path)
          size_old = File.size(raw_path)
        end

        # Notify
        Nanoc3::NotificationCenter.post(:will_write_rep, self, snapshot)

        if self.binary?
          # Calculate characteristics of new content
          size_new = File.size(temporary_filenames[:last])
          hash_new = Nanoc3::Checksummer.checksum_for_file(temporary_filenames[:last]) if size_old == size_new

          # Check whether content was modified
          is_modified = (size_old != size_new || hash_old != hash_new)

          # Copy
          if is_modified
            FileUtils.cp(temporary_filenames[:last], raw_path)
          end
        else
          # Check whether content was modified
          is_modified = (!File.file?(raw_path) || File.read(raw_path) != @content[:last])

          # Write
          if is_modified
            File.open(raw_path, 'w') { |io| io.write(@content[:last]) }
          end
        end

        # Notify
        Nanoc3::NotificationCenter.post(:rep_written, self, raw_path, is_created, is_modified)
      end

      # Resets the compilation progress for this item representation. This is
      # necessary when an unmet dependency is detected during compilation.
      #
      # @api private
      #
      # @return [void]
      def forget_progress
        initialize_content
      end

      # Returns the type of this object. Will always return `:item_rep`,
      # because this is an item rep. For layouts, this method returns
      # `:layout`.
      #
      # @api private
      #
      # @return [Symbol] :item_rep
      def type
        :item_rep
      end

    end

    include Deprecated
    include Private

    # @return [Nanoc3::Item] The item to which this rep belongs
    attr_reader   :item

    # @return [Symbol] The representation's unique name
    attr_reader   :name

    # @return [Boolean] true if this rep is currently binary; false otherwise
    attr_reader   :binary
    alias_method  :binary?, :binary

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

      # Set default attributes
      @raw_paths  = {}
      @paths      = {}
      @assigns    = {}
      initialize_content

      # Reset flags
      @compiled = false
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
      raise Nanoc3::Errors::UnmetDependency.new(self) if !compiled? && !params[:force]

      # Get name of last pre-layout snapshot
      snapshot_name = params[:snapshot]
      if @content[:pre]
        snapshot_name ||= :pre
      else
        snapshot_name ||= :last
      end

      # Check presence of snapshot
      if @content[snapshot_name].nil?
        warn(('-' * 78 + "\nWARNING: The “#{self.item.identifier}” item (rep “#{self.name}”) does not have the requested snapshot named #{snapshot_name.inspect}.\n\n* Make sure that you are requesting the correct snapshot.\n* It is not possible to request the compiled content of a binary item representation; if this item is marked as binary even though you believe it should be textual, you may need to add the extension of this item to the site configuration’s `text_extensions` array.\n" + '-' * 78).make_compatible_with_env)
      end

      # Get content
      @content[snapshot_name]
    end

    # Checks whether content exists at a given snapshot.
    #
    # @return [Boolean] True if content exists for the snapshot with the
    #   given name, false otherwise
    def has_snapshot?(snapshot_name)
      !@content[snapshot_name].nil?
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

    # Runs the item content through the given filter with the given arguments.
    # This method will replace the content of the `:last` snapshot with the
    # filtered content of the last snapshot.
    #
    # This method is supposed to be called only in a compilation rule block
    # (see {Nanoc3::CompilerDSL#compile}).
    #
    # @see Nanoc3::ItemRepProxy#filter
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

      begin
        # Notify start
        Nanoc3::NotificationCenter.post(:filtering_started, self, filter_name)

        # Create filter
        filter = klass.new(assigns)

        # Run filter
        source = self.binary? ? temporary_filenames[:last] : @content[:last]
        result = filter.run(source, filter_args)
        if klass.to_binary?
          temporary_filenames[:last] = filter.output_filename
        else
          @content[:last] = result
          @content[:last].freeze
        end
        @binary = klass.to_binary?

        # Check whether file was written
        if self.binary? && !File.file?(filter.output_filename)
          raise RuntimeError,
            "The #{filter_name.inspect} filter did not write anything to the required output file, #{filter.output_filename}."
        end

        # Create snapshot
        snapshot(@content[:post] ? :post : :pre, :final => false) unless self.binary?
      ensure
        # Notify end
        Nanoc3::NotificationCenter.post(:filtering_ended, self, filter_name)
      end
    end

    # Lays out the item using the given layout. This method will replace the
    # content of the `:last` snapshot with the laid out content of the last
    # snapshot.
    #
    # This method is supposed to be called only in a compilation rule block
    # (see {Nanoc3::CompilerDSL#compile}).
    #
    # @see Nanoc3::ItemRepProxy#layout
    #
    # @param [Nanoc3::Layout] layout The layout to use
    #
    # @param [Symbol] filter_name The name of the filter to layout the item
    #   representations' content with
    #
    # @param [Hash] filter_args The filter arguments that should be passed to
    #   the filter's #run method
    #
    # @return [void]
    def layout(layout, filter_name, filter_args)
      # Check whether item can be laid out
      raise Nanoc3::Errors::CannotLayoutBinaryItem.new(self) if self.binary?

      # Create "pre" snapshot
      if @content[:post].nil?
        snapshot(:pre, :final => true)
      end

      # Create filter
      klass = filter_named(filter_name)
      raise Nanoc3::Errors::UnknownFilter.new(filter_name) if klass.nil?
      filter = klass.new(assigns.merge({ :layout => layout }))

      # Visit
      Nanoc3::NotificationCenter.post(:visit_started, layout)
      Nanoc3::NotificationCenter.post(:visit_ended,   layout)

      # Notify start
      Nanoc3::NotificationCenter.post(:processing_started, layout)
      Nanoc3::NotificationCenter.post(:filtering_started,  self, filter_name)

      # Layout
      @content[:last] = filter.run(layout.raw_content, filter_args)

      # Create "post" snapshot
      snapshot(:post, :final => false)
    ensure
      # Notify end
      Nanoc3::NotificationCenter.post(:filtering_ended,    self, filter_name)
      Nanoc3::NotificationCenter.post(:processing_ended,   layout)
    end

    # Creates a snapshot of the current compiled item content.
    #
    # @param [Symbol] snapshot_name The name of the snapshot to create
    #
    # @option params [Boolean] :final (true) True if this is the final time
    #   the snapshot will be updated; false if it is a non-final moving
    #   snapshot (such as `:pre`, `:post` or `:last`)
    #
    # @return [void]
    def snapshot(snapshot_name, params={})
      # Parse params
      params[:final] = true if !params.has_key?(:final)

      # Create snapshot
      @content[snapshot_name] = @content[:last] unless self.binary?

      # Write
      write(snapshot_name) if params[:final]
    end

    # Returns a recording proxy that is used for determining whether the
    # compilation has changed, and thus whether the item rep needs to be
    # recompiled.
    #
    # @api private
    #
    # @return [Nanoc3::ItemRepRecorderProxy] The recording proxy
    def to_recording_proxy
      Nanoc3::ItemRepRecorderProxy.new(self)
    end

    # Returns false because this item is not yet a proxy, and therefore does
    # need to be wrapped in a proxy during compilation.
    #
    # @api private
    #
    # @return [false]
    #
    # @see Nanoc3::ItemRepRecorderProxy#is_proxy?
    # @see Nanoc3::ItemRepProxy#is_proxy?
    def is_proxy?
      false
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [ type, self.item.identifier, self.name ]
    end

    def inspect
      "<#{self.class}:0x#{self.object_id.to_s(16)} name=#{self.name} binary=#{self.binary?} raw_path=#{self.raw_path} item.identifier=#{self.item.identifier}>"
    end

  private

    def initialize_content
      # Initialize content and filenames
      if self.binary?
        @temporary_filenames = { :last => @item.raw_filename }
        @content             = {}
      else
        @content             = { :last => @item.raw_content }
        @content[:last].freeze
        @temporary_filenames = {}
      end
    end

    def filter_named(name)
      Nanoc3::Filter.named(name)
    end

  end

end
