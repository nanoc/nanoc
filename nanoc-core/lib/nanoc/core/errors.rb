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

      # Error that is raised when compilation of an item rep fails. The
      # underlying error is available by calling `#unwrap`.
      class CompilationError < ::Nanoc::Core::Error
        attr_reader :item_rep

        def initialize(wrapped, item_rep)
          @wrapped = wrapped
          @item_rep = item_rep
        end

        def unwrap
          @wrapped
        end
      end

      # Error that is raised when a site is loaded that uses a data source with
      # an unknown identifier.
      class UnknownDataSource < ::Nanoc::Core::Error
        # @param [String] data_source_name The data source name for which no
        #   data source could be found
        def initialize(data_source_name)
          super("The data source specified in the site’s configuration file, “#{data_source_name}”, does not exist.")
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

      # Error that is raised during site compilation when an item (directly or
      # indirectly) includes its own item content, leading to endless recursion.
      class DependencyCycle < ::Nanoc::Core::Error
        def initialize(cycle)
          msg_bits = []
          msg_bits << 'The site cannot be compiled because there is a dependency cycle:'
          msg_bits << ''
          cycle.each.with_index do |r, i|
            msg_bits << "    (#{i + 1}) item #{r.item.identifier}, rep #{r.name.inspect}, uses compiled content of"
          end
          msg_bits << msg_bits.pop + ' (1)'

          super(msg_bits.map { |x| x + "\n" }.join(''))
        end
      end

      # Error that is raised during site compilation when a layout is compiled
      # for which the filter cannot be determined. This is similar to the
      # {UnknownFilter} error, but specific for filters for layouts.
      class CannotDetermineFilter < ::Nanoc::Core::Error
        # @param [String] layout_identifier The identifier of the layout for
        #   which the filter could not be determined
        def initialize(layout_identifier)
          super("The filter to be used for the “#{layout_identifier}” layout could not be determined. Make sure the layout does have a filter.")
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

      # Error that is raised during site compilation when an item uses a layout
      # that is not present in the site.
      class UnknownLayout < ::Nanoc::Core::Error
        # @param [String] layout_identifier The layout identifier for which no
        #   layout could be found
        def initialize(layout_identifier)
          super("The site does not have a layout with identifier “#{layout_identifier}”.")
        end
      end

      # Error that is raised when a binary item is attempted to be laid out.
      class CannotLayoutBinaryItem < ::Nanoc::Core::Error
        # @param [Nanoc::Core::ItemRep] rep The item representation that was attempted
        #   to be laid out
        def initialize(rep)
          super("The “#{rep.item.identifier}” item (rep “#{rep.name}”) cannot be laid out because it is a binary item. If you are getting this error for an item that should be textual instead of binary, make sure that its extension is included in the text_extensions array in the site configuration.")
        end
      end

      # Error that is raised when a textual filter is attempted to be applied to
      # a binary item representation.
      class CannotUseTextualFilter < ::Nanoc::Core::Error
        # @param [Nanoc::Core::ItemRep] rep The item representation that was
        #   attempted to be filtered
        #
        # @param [Class] filter_class The filter class that was used
        def initialize(rep, filter_class)
          super("The “#{filter_class.inspect}” filter cannot be used to filter the “#{rep.item.identifier}” item (rep “#{rep.name}”), because textual filters cannot be used on binary items.")
        end
      end

      # Error that is raised when a binary filter is attempted to be applied to
      # a textual item representation.
      class CannotUseBinaryFilter < ::Nanoc::Core::Error
        # @param [Nanoc::Core::ItemRep] rep The item representation that was
        #   attempted to be filtered
        #
        # @param [Class] filter_class The filter class that was used
        def initialize(rep, filter_class)
          super("The “#{filter_class.inspect}” filter cannot be used to filter the “#{rep.item.identifier}” item (rep “#{rep.name}”), because binary filters cannot be used on textual items. If you are getting this error for an item that should be textual instead of binary, make sure that its extension is included in the text_extensions array in the site configuration.")
        end
      end

      class InternalInconsistency < ::Nanoc::Core::Error
      end
    end
  end
end
