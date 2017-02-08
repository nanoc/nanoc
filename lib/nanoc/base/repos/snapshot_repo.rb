module Nanoc::Int
  # @api private
  class SnapshotRepo
    include Nanoc::Int::ContractsSupport

    def initialize
      @contents = {}
    end

    contract Nanoc::Int::ItemRep, Symbol => C::Maybe[Nanoc::Int::Content]
    def get(rep, snapshot_name)
      @contents[rep] ||= {}
      @contents[rep][snapshot_name]
    end

    contract Nanoc::Int::ItemRep, Symbol, Nanoc::Int::Content => C::Any
    def set(rep, snapshot_name, contents)
      @contents[rep] ||= {}
      @contents[rep][snapshot_name] = contents
    end

    contract Nanoc::Int::ItemRep => C::HashOf[Symbol => Nanoc::Int::Content]
    def get_all(rep)
      @contents[rep] || {}
    end

    contract Nanoc::Int::ItemRep, C::HashOf[Symbol => Nanoc::Int::Content] => C::Any
    def set_all(rep, contents_per_snapshot)
      @contents[rep] = contents_per_snapshot
    end

    contract C::KeywordArgs[rep: Nanoc::Int::ItemRep, snapshot: C::Optional[C::Maybe[Symbol]]] => Nanoc::Int::Content
    def raw_compiled_content(rep:, snapshot: nil)
      # Get name of last pre-layout snapshot
      snapshot_name = snapshot || (get(rep, :pre) ? :pre : :last)

      # Check existance of snapshot
      snapshot_def = rep.snapshot_defs.reverse.find { |sd| sd.name == snapshot_name }
      unless snapshot_def
        raise Nanoc::Int::Errors::NoSuchSnapshot.new(rep, snapshot_name)
      end

      # Verify snapshot is usable
      stopped_moving = snapshot_name != :last || rep.compiled?
      is_usable_snapshot = get(rep, snapshot_name) && stopped_moving
      unless is_usable_snapshot
        Fiber.yield(Nanoc::Int::Errors::UnmetDependency.new(rep))
        return raw_compiled_content(rep: rep, snapshot: snapshot)
      end

      get(rep, snapshot_name)
    end

    contract C::KeywordArgs[rep: Nanoc::Int::ItemRep, snapshot: C::Optional[C::Maybe[Symbol]]] => String
    def compiled_content(rep:, snapshot: nil)
      snapshot_content = raw_compiled_content(rep: rep, snapshot: snapshot)

      if snapshot_content.binary?
        raise Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem.new(rep)
      end

      snapshot_content.string
    end
  end
end
