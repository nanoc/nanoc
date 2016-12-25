module Nanoc::Int
  # @api private
  class ItemRep
    include Nanoc::Int::ContractsSupport

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

    contract Nanoc::Int::Item, Symbol => C::Any
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
      @snapshot_contents = { last: @item.content }

      # Reset flags
      @compiled = false
    end

    # TODO: remove me
    contract C::None => C::Bool
    def binary?
      @snapshot_contents[:last].binary?
    end

    contract C::KeywordArgs[snapshot: C::Optional[C::Maybe[Symbol]]] => String
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
      # Get name of last pre-layout snapshot
      snapshot_name = snapshot || (@snapshot_contents[:pre] ? :pre : :last)

      # Check existance of snapshot
      snapshot_def = snapshot_defs.reverse.find { |sd| sd.name == snapshot_name }
      unless snapshot_def
        raise Nanoc::Int::Errors::NoSuchSnapshot.new(self, snapshot_name)
      end

      # Verify snapshot is usable
      stopped_moving = snapshot_name != :last || compiled?
      is_usable_snapshot = @snapshot_contents[snapshot_name] && stopped_moving
      unless is_usable_snapshot
        Fiber.yield(Nanoc::Int::Errors::UnmetDependency.new(self))
        return compiled_content(snapshot: snapshot)
      end

      # Verify snapshot is not binary
      snapshot_content = @snapshot_contents[snapshot_name]
      if snapshot_content.binary?
        raise Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem.new(self)
      end

      snapshot_content.string
    end

    contract C::KeywordArgs[snapshot: C::Optional[Symbol]] => C::Maybe[String]
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

    contract C::KeywordArgs[snapshot: C::Optional[Symbol]] => C::Maybe[String]
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

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [:item_rep, item.identifier, name]
    end

    def inspect
      "<#{self.class} name=\"#{name}\" raw_path=\"#{raw_path}\" item.identifier=\"#{item.identifier}\">"
    end
  end
end
