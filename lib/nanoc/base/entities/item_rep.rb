module Nanoc::Int
  # @api private
  class ItemRep
    # @return [Hash<Symbol,Nanoc::Int::Content>]
    attr_accessor :snapshot_contents

    # @return [Boolean]
    attr_accessor :compiled
    alias compiled? compiled

    # @return [Hash<Symbol,String>]
    attr_accessor :raw_paths

    # @return [Hash<Symbol,String>]
    attr_accessor :paths

    # @return [Nanoc::Int::Item]
    attr_reader :item

    # @return [Symbol]
    attr_reader :name

    # @return [Enumerable<Nanoc::Int:SnapshotDef]
    attr_accessor :snapshot_defs

    # @return [Boolean]
    attr_accessor :modified
    alias modified? modified

    # @param [Nanoc::Int::Item] item
    #
    # @param [Symbol] name
    def initialize(item, name)
      # Set primary attributes
      @item   = item
      @name   = name

      # Set default attributes
      @raw_paths  = {}
      @paths      = {}
      @snapshot_defs = []
      initialize_content

      # Reset flags
      @compiled = false
    end

    def binary?
      @snapshot_contents[:last].binary?
    end

    # Returns the compiled content from a given snapshot.
    #
    # @param [Symbol] snapshot The name of the snapshot from which to
    #   fetch the compiled content. By default, the returned compiled content
    #   will be the content compiled right before the first layout call (if
    #   any).
    #
    # @return [String] The compiled content at the given snapshot (or the
    #   default snapshot if no snapshot is specified)
    def compiled_content(snapshot: nil)
      # Make sure we're not binary
      if binary?
        raise Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem.new(self)
      end

      # Get name of last pre-layout snapshot
      snapshot_name = snapshot || (@snapshot_contents[:pre] ? :pre : :last)
      is_moving = [:pre, :post, :last].include?(snapshot_name)

      # Check existance of snapshot
      snapshot_def = snapshot_defs.reverse.find { |sd| sd.name == snapshot_name }
      if !is_moving && (snapshot_def.nil? || !snapshot_def.final?)
        raise Nanoc::Int::Errors::NoSuchSnapshot.new(self, snapshot_name)
      end

      # Verify snapshot is usable
      is_still_moving =
        case snapshot_name
        when :post, :last
          true
        when :pre
          snapshot_def.nil? || !snapshot_def.final?
        end
      is_usable_snapshot = @snapshot_contents[snapshot_name] && (compiled? || !is_still_moving)
      unless is_usable_snapshot
        raise Nanoc::Int::Errors::UnmetDependency.new(self)
      end

      @snapshot_contents[snapshot_name].string
    end

    # Checks whether content exists at a given snapshot.
    #
    # @return [Boolean] True if content exists for the snapshot with the
    #   given name, false otherwise
    #
    # @since 3.2.0
    def snapshot?(snapshot_name)
      !@snapshot_contents[snapshot_name].nil?
    end
    alias has_snapshot? snapshot?

    # Returns the item rep’s raw path. It includes the path to the output
    # directory and the full filename.
    #
    # @param [Symbol] snapshot The snapshot for which the path should be
    #   returned
    #
    # @return [String] The item rep’s path
    def raw_path(snapshot: :last)
      @raw_paths[snapshot]
    end

    # Returns the item rep’s path, as used when being linked to. It starts
    # with a slash and it is relative to the output directory. It does not
    # include the path to the output directory. It will not include the
    # filename if the filename is an index filename.
    #
    # @param [Symbol] snapshot The snapshot for which the path should be
    #   returned
    #
    # @return [String] The item rep’s path
    def path(snapshot: :last)
      @paths[snapshot]
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

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [:item_rep, item.identifier, name]
    end

    def inspect
      "<#{self.class} name=\"#{name}\" binary=#{binary?} raw_path=\"#{raw_path}\" item.identifier=\"#{item.identifier}\">"
    end

    private

    def initialize_content
      # FIXME: Where is :raw?
      @snapshot_contents = { last: @item.content }
    end
  end
end
