module Nanoc::Int
  # @api private
  class ItemRep
    include Nanoc::Int::ContractsSupport

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

      # Reset flags
      @compiled = false
    end

    contract Symbol => C::Bool
    def snapshot?(name)
      snapshot_defs.any? { |sd| sd.name == name }
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
