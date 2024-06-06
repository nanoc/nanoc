# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    class CompiledContentStore
      include Nanoc::Core::ContractsSupport

      def initialize
        @contents = Hash.new { |hash, rep| hash[rep] = {} }
        @current_content = {}
      end

      contract Nanoc::Core::ItemRep, Symbol => C::Maybe[Nanoc::Core::Content]
      def get(rep, snapshot_name)
        @contents[rep][snapshot_name]
      end

      contract Nanoc::Core::ItemRep => C::Maybe[Nanoc::Core::Content]
      def get_current(rep)
        @current_content[rep]
      end

      contract Nanoc::Core::ItemRep, Symbol, Nanoc::Core::Content => C::Any
      def set(rep, snapshot_name, contents)
        @contents[rep][snapshot_name] = contents
      end

      contract Nanoc::Core::ItemRep, Nanoc::Core::Content => C::Any
      def set_current(rep, content)
        @current_content[rep] = content
      end

      contract Nanoc::Core::ItemRep => C::HashOf[Symbol => Nanoc::Core::Content]
      def get_all(rep)
        @contents[rep]
      end

      contract Nanoc::Core::ItemRep, C::HashOf[Symbol => Nanoc::Core::Content] => C::Any
      def set_all(rep, contents_per_snapshot)
        @contents[rep] = contents_per_snapshot
      end

      contract C::KeywordArgs[rep: Nanoc::Core::ItemRep, snapshot: C::Optional[C::Maybe[Symbol]]] => Nanoc::Core::Content
      def raw_compiled_content(rep:, snapshot: nil)
        # Get name of last pre-layout snapshot
        has_pre = rep.snapshot_defs.any? { |sd| sd.name == :pre }
        snapshot_name = snapshot || (has_pre ? :pre : :last)

        # Check existance of snapshot
        snapshot_def = rep.snapshot_defs.reverse.find { |sd| sd.name == snapshot_name }
        unless snapshot_def
          raise Nanoc::Core::Errors::NoSuchSnapshot.new(rep, snapshot_name)
        end

        # Return content if it is available
        content = get(rep, snapshot_name)
        return content if content

        # Content is unavailable; notify and try again
        Fiber.yield(Nanoc::Core::Errors::UnmetDependency.new(rep, snapshot_name))
        get(rep, snapshot_name)
      end

      contract C::KeywordArgs[rep: Nanoc::Core::ItemRep, snapshot: C::Optional[C::Maybe[Symbol]]] => String
      def compiled_content(rep:, snapshot: nil)
        snapshot_content = raw_compiled_content(rep:, snapshot:)

        if snapshot_content.binary?
          raise Nanoc::Core::Errors::CannotGetCompiledContentOfBinaryItem.new(rep)
        end

        snapshot_content.string
      end
    end
  end
end
