module Nanoc::Int
  # A single representation (rep) of an item ({Nanoc::Int::Item}). An item can
  # have multiple representations. A representation has its own output file.
  # A single item can therefore have multiple output files, each run through
  # a different set of filters with a different layout.
  #
  # @api private
  class ItemRep
    # Contains all private methods. Mixed into {Nanoc::Int::ItemRep}.
    #
    # @api private
    module Private
      attr_accessor :content_snapshots

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

      # Resets the compilation progress for this item representation. This is
      # necessary when an unmet dependency is detected during compilation.
      #
      # @api private
      #
      # @return [void]
      def forget_progress
        initialize_content
      end
    end

    include Private

    # @return [Nanoc::Int::Item] The item to which this rep belongs
    attr_reader :item

    # @return [Symbol] The representation's unique name
    attr_reader :name

    # @return [Array] A list of snapshots, represented as arrays where the
    #   first element is the snapshot name (a Symbol) and the last element is
    #   a Boolean indicating whether the snapshot is final or not
    attr_accessor :snapshots

    # Creates a new item representation for the given item.
    #
    # @param [Nanoc::Int::Item] item The item to which the new representation will
    #   belong.
    #
    # @param [Symbol] name The unique name for the new item representation.
    def initialize(item, name)
      # Set primary attributes
      @item   = item
      @name   = name

      # Set default attributes
      @raw_paths  = {}
      @paths      = {}
      @snapshots  = []
      initialize_content

      # Reset flags
      @compiled = false
    end

    def binary?
      @content_snapshots[:last].binary?
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
    def compiled_content(params = {})
      # Make sure we're not binary
      if binary?
        raise Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem.new(self)
      end

      # Get name of last pre-layout snapshot
      snapshot_name = params.fetch(:snapshot) { @content_snapshots[:pre] ? :pre : :last }
      is_moving = [:pre, :post, :last].include?(snapshot_name)

      # Check existance of snapshot
      snapshot = snapshots.find { |s| s.name == snapshot_name }
      if !is_moving && (snapshot.nil? || !snapshot.final?)
        raise Nanoc::Int::Errors::NoSuchSnapshot.new(self, snapshot_name)
      end

      # Verify snapshot is usable
      is_still_moving =
        case snapshot_name
        when :post, :last
          true
        when :pre
          snapshot.nil? || !snapshot.final?
        end
      is_usable_snapshot = @content_snapshots[snapshot_name] && (self.compiled? || !is_still_moving)
      unless is_usable_snapshot
        raise Nanoc::Int::Errors::UnmetDependency.new(self)
      end

      @content_snapshots[snapshot_name].string
    end

    # Checks whether content exists at a given snapshot.
    #
    # @return [Boolean] True if content exists for the snapshot with the
    #   given name, false otherwise
    #
    # @since 3.2.0
    def snapshot?(snapshot_name)
      !@content_snapshots[snapshot_name].nil?
    end
    alias_method :has_snapshot?, :snapshot?

    # Returns the item rep’s raw path. It includes the path to the output
    # directory and the full filename.
    #
    # @option params [Symbol] :snapshot (:last) The snapshot for which the
    #   path should be returned
    #
    # @return [String] The item rep’s path
    def raw_path(params = {})
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
    def path(params = {})
      snapshot_name = params[:snapshot] || :last
      @paths[snapshot_name]
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [:item_rep, item.identifier, name]
    end

    def inspect
      "<#{self.class} name=\"#{name}\" binary=#{self.binary?} raw_path=\"#{raw_path}\" item.identifier=\"#{item.identifier}\">"
    end

    private

    def initialize_content
      # FIXME: Where is :raw?
      @content_snapshots = { last: @item.content }
    end
  end
end
