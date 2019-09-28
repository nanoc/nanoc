# frozen_string_literal: true

module Nanoc
  module Int
    # Module that contains all Nanoc-specific errors.
    #
    # @api private
    module Errors
      Generic = ::Nanoc::Error

      NoSuchSnapshot = ::Nanoc::Core::Errors::NoSuchSnapshot
      CannotGetCompiledContentOfBinaryItem = ::Nanoc::Core::Errors::CannotGetCompiledContentOfBinaryItem
      CannotGetParentOrChildrenOfNonLegacyItem = ::Nanoc::Core::Errors::CannotGetParentOrChildrenOfNonLegacyItem
      InternalInconsistency = ::Nanoc::Core::Errors::InternalInconsistency
      CannotLayoutBinaryItem = ::Nanoc::Core::Errors::CannotLayoutBinaryItem
      UnknownLayout = ::Nanoc::Core::Errors::UnknownLayout
      CannotUseBinaryFilter = ::Nanoc::Core::Errors::CannotUseBinaryFilter
      CannotUseTextualFilter = ::Nanoc::Core::Errors::CannotUseTextualFilter

      # Generic trivial error. Superclass for all Nanoc-specific errors that are
      # considered "trivial", i.e. errors that do not require a full crash report.
      class GenericTrivial < Generic
      end

      # Error that is raised during site compilation when a layout is compiled
      # for which the filter cannot be determined. This is similar to the
      # {UnknownFilter} error, but specific for filters for layouts.
      class CannotDetermineFilter < Generic
        # @param [String] layout_identifier The identifier of the layout for
        #   which the filter could not be determined
        def initialize(layout_identifier)
          super("The filter to be used for the “#{layout_identifier}” layout could not be determined. Make sure the layout does have a filter.")
        end
      end

      # Error that is raised when no rules file can be found in the current
      # working directory.
      class NoRulesFileFound < Generic
        def initialize
          super('This site does not have a rules file, which is required for Nanoc sites.')
        end
      end

      # Error that is raised when no compilation rule that can be applied to the
      # current item can be found.
      class NoMatchingCompilationRuleFound < Generic
        # @param [Nanoc::Core::Item] item The item for which no compilation rule
        #   could be found
        def initialize(item)
          super("No compilation rules were found for the “#{item.identifier}” item.")
        end
      end

      # Error that is raised when no routing rule that can be applied to the
      # current item can be found.
      class NoMatchingRoutingRuleFound < Generic
        # @param [Nanoc::Core::ItemRep] rep The item repiresentation for which no
        #   routing rule could be found
        def initialize(rep)
          super("No routing rules were found for the “#{rep.item.identifier}” item (rep “#{rep.name}”).")
        end
      end

      class AmbiguousMetadataAssociation < Generic
        def initialize(content_filenames, meta_filename)
          super("There are multiple content files (#{content_filenames.sort.join(', ')}) that could match the file containing metadata (#{meta_filename}).")
        end
      end
    end
  end
end
