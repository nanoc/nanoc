# encoding: utf-8

# Kinds of item reps:
#
# - core entity
# - in rules (#filter, #layout, #snapshot, #[], #path, ...)
# - in compilation context (#[], #path, ...)

module Nanoc

  # A single representation (rep) of an item ({Nanoc::Item}). An item can
  # have multiple representations. A representation has its own output file.
  # A single item can therefore have multiple output files, each run through
  # a different set of filters with a different layout.
  class ItemRep

    # Contains all private methods. Mixed into {Nanoc::ItemRep}.
    module Private

      # @return [Nanoc::SnapshotStore] The snapshot store to store content in
      attr_accessor :snapshot_store

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

      # @return [Array<String>] A list of paths in direct #write calls
      attr_accessor :paths_without_snapshot

      # @return [Hash<Symbol,String>] A hash containing the paths for all
      #   snapshots. The keys correspond with the snapshot names, and the
      #   values with the path.
      #
      # @api private
      attr_accessor :paths

      # @return [Hash<Symbol,String>] A hash containing the paths to the
      #   temporary _files_ that filters write binary content to. This is only
      #   used when the item representation is binary. The keys correspond
      #   with the snapshot names, and the values with the filename.
      #
      # @api private
      attr_reader :temporary_filenames

      # @return [Hash<Symbol,String>] A hash containing the content at all
      #   snapshots. The keys correspond with the snapshot names, and the
      #   values with the content.
      #
      # @api private
      attr_accessor :content

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

    include Private

    # @return [Nanoc::Item] The item to which this rep belongs
    attr_reader   :item

    # @return [Symbol] The representation's unique name
    attr_reader   :name

    # @return [Array] A list of snapshots, represented as arrays where the
    #   first element is the snapshot name (a Symbol) and the last element is
    #   a Boolean indicating whether the snapshot is final or not
    # TODO simplify
    attr_accessor :snapshots

    # Creates a new item representation for the given item.
    #
    # @param [Nanoc::Item] item The item to which the new representation will
    #   belong.
    #
    # @param [Symbol] name The unique name for the new item representation.
    #
    # @option params [Nanoc::SnapshotStore] :snapshot_store The snapshot
    #   store to use for the item rep (required)
    def initialize(item, name, params={})
      # Set primary attributes
      @item   = item
      @name   = name
      @snapshot_store = params.fetch(:snapshot_store)

      # Set binary
      @binaryness = { :last => @item.content.binary? }

      # Set default attributes
      @raw_paths  = {}
      @paths_without_snapshot = []
      @paths      = {}
      @assigns    = {}
      @snapshots  = []
      @content    = { :last => @item.content }
      initialize_content

      # Reset flags
      @compiled = false
    end

    def snapshot_binary?(snapshot)
      @binaryness[snapshot]
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
      Nanoc::NotificationCenter.post(:visit_started, self.item)
      Nanoc::NotificationCenter.post(:visit_ended,   self.item)

      # Get name of last pre-layout snapshot
      snapshot = params.fetch(:snapshot, :last)
      is_moving = :last == snapshot

      # Make sure we're not binary
      if self.snapshot_binary?(snapshot)
        raise Nanoc::Errors::CannotGetCompiledContentOfBinaryItem.new(self)
      end

      # Check existance of snapshot
      if !is_moving && snapshots.find { |s| s.first == snapshot && s.last == true }.nil?
        raise Nanoc::Errors::NoSuchSnapshot.new(self, snapshot)
      end

      # Require compilation
      if !self.has_snapshot?(snapshot) || (!self.compiled? && is_moving)
        raise Nanoc::Errors::UnmetDependency.new(self)
      else
        self.stored_content_at_snapshot(snapshot)
      end
    end

    # @param [Symbol] snapshot_name The name of the snapshot to fetch the content for
    #
    # @return [String] The content at the given snapshot
    def stored_content_at_snapshot(snapshot_name)
      self.snapshot_store.query(self.item.identifier, self.name, snapshot_name)
    end

    # @param [Symbol] snapshot_name The name of the snapshot to set the content for
    #
    # @param [String] compiled_content The content to store for the given snapshot name
    #
    # @return [void]
    def set_stored_content_at_snapshot(snapshot_name, compiled_content)
      self.snapshot_store.set(self.item.identifier, self.name, snapshot_name, compiled_content)
    end

    # Checks whether content exists at a given snapshot.
    #
    # @return [Boolean] True if content exists for the snapshot with the
    #   given name, false otherwise
    def has_snapshot?(snapshot_name)
      self.snapshot_store.exist?(self.item.identifier, self.name, snapshot_name)
    end

    # Returns the item rep’s raw path. It includes the path to the output
    # directory and the full filename.
    #
    # @option params [Symbol] :snapshot (:last) The snapshot for which the
    #   path should be returned
    #
    # @return [String] The item rep’s path
    def raw_path(params={})
      Nanoc::NotificationCenter.post(:visit_started, self.item)
      Nanoc::NotificationCenter.post(:visit_ended,   self.item)

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
      Nanoc::NotificationCenter.post(:visit_started, self.item)
      Nanoc::NotificationCenter.post(:visit_ended,   self.item)

      snapshot_name = params[:snapshot] || :last
      @paths[snapshot_name]
    end

    # Runs the item content through the given filter with the given arguments.
    # This method will replace the content of the `:last` snapshot with the
    # filtered content of the last snapshot.
    #
    # This method is supposed to be called only in a compilation rule block
    # (see {Nanoc::CompilerDSL#compile}).
    #
    # @see Nanoc::ItemRepRulesProxy#filter
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
      raise Nanoc::Errors::UnknownFilter.new(filter_name) if klass.nil?

      # Check whether filter can be applied
      if klass.from_binary? && !self.snapshot_binary?(:last)
        raise Nanoc::Errors::CannotUseBinaryFilter.new(self, klass)
      elsif !klass.from_binary? && self.snapshot_binary?(:last)
        raise Nanoc::Errors::CannotUseTextualFilter.new(self, klass)
      end

      begin
        # Notify start
        Nanoc::NotificationCenter.post(:filtering_started, self, filter_name)

        # Create filter
        filter = klass.new(assigns)

        # Run filter
        source =
          if self.snapshot_binary?(:last)
            temporary_filenames[:last]
          else
            self.stored_content_at_snapshot(:last)
          end
        result = filter.setup_and_run(source, filter_args)
        if klass.to_binary?
          temporary_filenames[:last] = filter.output_filename
        else
          self.set_stored_content_at_snapshot(:last, result)
          result.freeze
        end
        @binaryness[:last] = klass.to_binary?

        # Check whether file was written
        if self.snapshot_binary?(:last) && !File.file?(filter.output_filename)
          raise RuntimeError,
            "The #{filter_name.inspect} filter did not write anything to the required output file, #{filter.output_filename}."
        end
      ensure
        # Notify end
        Nanoc::NotificationCenter.post(:filtering_ended, self, filter_name)
      end
    end

    # Lays out the item using the given layout. This method will replace the
    # content of the `:last` snapshot with the laid out content of the last
    # snapshot.
    #
    # This method is supposed to be called only in a compilation rule block
    # (see {Nanoc::CompilerDSL#compile}).
    #
    # @see Nanoc::ItemRepRulesProxy#layout
    #
    # @param [Nanoc::Layout] layout The layout to use
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
      raise Nanoc::Errors::CannotLayoutBinaryItem.new(self) if self.snapshot_binary?(:last)

      # Create filter
      klass = filter_named(filter_name)
      raise Nanoc::Errors::UnknownFilter.new(filter_name) if klass.nil?
      filter = klass.new(assigns.merge({ :layout => layout }))

      # Visit
      Nanoc::NotificationCenter.post(:visit_started, layout)
      Nanoc::NotificationCenter.post(:visit_ended,   layout)

      begin
        # Notify start
        Nanoc::NotificationCenter.post(:processing_started, layout)
        Nanoc::NotificationCenter.post(:filtering_started,  self, filter_name)

        # Layout
        if layout.content.binary?
          raise "cannot use binary layouts"
        end
        content = filter.setup_and_run(layout.content.string, filter_args)
        self.set_stored_content_at_snapshot(:last, content)
      ensure
        # Notify end
        Nanoc::NotificationCenter.post(:filtering_ended,  self, filter_name)
        Nanoc::NotificationCenter.post(:processing_ended, layout)
      end
    end

    # Creates a snapshot of the current compiled item content.
    #
    # @param [Symbol] snapshot_name The name of the snapshot to create
    #
    # @option params [String] :path The name of path corresponding to the
    #   snapshot (only available when the snapshot is written)
    #
    # @return [void]
    def snapshot(snapshot_name, params={})
      # TODO make this work with binary ones as well
      if !self.snapshot_binary?(:last)
        self.set_stored_content_at_snapshot(snapshot_name, self.stored_content_at_snapshot(:last))
      end

      if params.has_key?(:path)
        @raw_paths[snapshot_name] = params[:path]
      end
    end

    # Returns a recording proxy that is used for determining whether the
    # compilation has changed, and thus whether the item rep needs to be
    # recompiled.
    #
    # @api private
    #
    # @return [Nanoc::ItemRepRecorderProxy] The recording proxy
    def to_recording_proxy
      Nanoc::ItemRepRecorderProxy.new(self)
    end

    # Returns false because this item is not yet a proxy, and therefore does
    # need to be wrapped in a proxy during compilation.
    #
    # @api private
    #
    # @return [false]
    #
    # @see Nanoc::ItemRepRecorderProxy#is_proxy?
    # @see Nanoc::ItemRepRulesProxy#is_proxy?
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
      "<#{self.class} name=\"#{self.name}\" raw_paths=#{self.raw_paths.inspect} paths_without_snapshot=#{self.paths_without_snapshot.inspect} item.identifier=\"#{self.item.identifier}\">"
    end

  private

    def initialize_content
      @temporary_filenames = {}
      if @item.content.binary?
        @temporary_filenames[:last] = @item.content.filename
      else
        self.snapshot_store.set(@item.identifier, self.name, :last, @item.content.string)
      end
    end

    def filter_named(name)
      Nanoc::Filter.named(name)
    end

  end

end
