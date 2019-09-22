# frozen_string_literal: true

module Nanoc
  module Core
    module Errors
      # Error that is raised when the compiled content at a non-existing snapshot
      # is requested.
      class NoSuchSnapshot < ::Nanoc::Core::Error
        # @return [Nanoc::Core::ItemRep] The item rep from which the compiled content
        #   was requested
        attr_reader :item_rep

        # @return [Symbol] The requested snapshot
        attr_reader :snapshot

        # @param [Nanoc::Core::ItemRep] item_rep The item rep from which the compiled
        #   content was requested
        #
        # @param [Symbol] snapshot The requested snapshot
        def initialize(item_rep, snapshot)
          @item_rep = item_rep
          @snapshot = snapshot
          super("The “#{item_rep.inspect}” item rep does not have a snapshot “#{snapshot.inspect}”")
        end
      end

      # Error that is raised when an rep cannot be compiled because it depends
      # on other representations.
      class UnmetDependency < ::Nanoc::Core::Error
        # @return [Nanoc::Core::ItemRep] The item representation that cannot yet be
        #   compiled
        attr_reader :rep

        # @return [Symbol] The name of the snapshot that cannot yet be compiled
        attr_reader :snapshot_name

        # @param [Nanoc::Core::ItemRep] rep The item representation that cannot yet be
        #   compiled
        def initialize(rep, snapshot_name)
          @rep = rep
          @snapshot_name = snapshot_name

          super("The current item cannot be compiled yet because of an unmet dependency on the “#{rep.item.identifier}” item (rep “#{rep.name}”, snapshot “#{snapshot_name}”).")
        end
      end

      # Error that is raised when the compiled content of a binary item is attempted to be accessed.
      class CannotGetCompiledContentOfBinaryItem < ::Nanoc::Core::Error
        # @param [Nanoc::Core::ItemRep] rep The binary item representation whose compiled content was attempted to be accessed
        def initialize(rep)
          super("You cannot access the compiled content of a binary item representation (but you can access the path). The offending item rep is #{rep}.")
        end
      end

      # Error that is raised when attempting to call #parent or #children on an item with a legacy identifier.
      class CannotGetParentOrChildrenOfNonLegacyItem < ::Nanoc::Core::Error
        def initialize(identifier)
          super("You cannot get the parent or children of an item that has a “full” identifier (#{identifier}). Getting the parent or children of an item is only possible for items that have a legacy identifier.")
        end
      end

      class InternalInconsistency < ::Nanoc::Core::Error
      end
    end
  end
end
