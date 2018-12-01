# frozen_string_literal: true

module Nanoc
  module Int
    # @api private
    class CompiledContentStore
      include Nanoc::Core::ContractsSupport

      def initialize
        @contents = Hash.new { |hash, rep| hash[rep] = {} }
        @contents_wait = {}
        @current_content = {}
        @mutex = Mutex.new
      end

      contract Nanoc::Core::ItemRep, Symbol => C::Maybe[Nanoc::Core::Content]
      def get(rep, snapshot_name)
        @mutex.synchronize do
          @contents[rep][snapshot_name]
        end
      end

      contract Nanoc::Core::ItemRep => C::Maybe[Nanoc::Core::Content]
      def get_current(rep)
        @current_content[rep]
      end

      def get_and_wait(rep, snapshot_name)
        waiter_for(rep, snapshot_name).value
        get(rep, snapshot_name)
      end

      contract Nanoc::Core::ItemRep, Symbol, Nanoc::Core::Content => C::Any
      def set(rep, snapshot_name, contents)
        @mutex.synchronize do
          @contents[rep][snapshot_name] = contents
        end

        # FIXME: can’t remove second argument, because the capturing helper can overwrite snapshots :(
        waiter_for(rep, snapshot_name).fulfill(true, false)
      end

      contract Nanoc::Core::ItemRep, Nanoc::Core::Content => C::Any
      def set_current(rep, content)
        @current_content[rep] = content
      end

      contract Nanoc::Core::ItemRep => C::HashOf[Symbol => Nanoc::Core::Content]
      def get_all(rep)
        @mutex.synchronize do
          @contents[rep]
        end
      end

      contract Nanoc::Core::ItemRep, C::HashOf[Symbol => Nanoc::Core::Content] => C::Any
      def set_all(rep, contents_per_snapshot)
        contents_per_snapshot.each do |snapshot_name, contents|
          set(rep, snapshot_name, contents)
        end
      end

      contract C::KeywordArgs[rep: Nanoc::Core::ItemRep, snapshot: C::Optional[C::Maybe[Symbol]]] => Nanoc::Core::Content
      def raw_compiled_content(rep:, snapshot: nil)
        # Get name of last pre-layout snapshot
        has_pre = rep.snapshot_defs.any? { |sd| sd.name == :pre }
        snapshot_name = snapshot || (has_pre ? :pre : :last)

        # Check existance of snapshot
        snapshot_def = rep.snapshot_defs.reverse.find { |sd| sd.name == snapshot_name }
        unless snapshot_def
          raise Nanoc::Int::Errors::NoSuchSnapshot.new(rep, snapshot_name)
        end

        # Return content if it is available
        content = get(rep, snapshot_name)
        return content if content

        # Content is unavailable; notify and try again
        Fiber.yield(Nanoc::Int::Errors::UnmetDependency.new(rep, snapshot_name))
        get_and_wait(rep, snapshot_name)
      end

      contract C::KeywordArgs[rep: Nanoc::Core::ItemRep, snapshot: C::Optional[C::Maybe[Symbol]]] => String
      def compiled_content(rep:, snapshot: nil)
        snapshot_content = raw_compiled_content(rep: rep, snapshot: snapshot)

        if snapshot_content.binary?
          raise Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem.new(rep)
        end

        snapshot_content.string
      end

      private

      def waiter_for(rep, snapshot_name)
        # FIXME: A future in a mutex?! Did a time rift open between 1999 and 2018?

        @mutex.synchronize do
          @contents_wait[rep] ||= {}
          @contents_wait[rep][snapshot_name] ||= Concurrent::Promises.resolvable_future
        end
      end
    end
  end
end
