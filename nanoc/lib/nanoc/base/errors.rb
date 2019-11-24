# frozen_string_literal: true

module Nanoc
  module Int
    # Module that contains all Nanoc-specific errors.
    #
    # @api private
    module Errors
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

      class AmbiguousMetadataAssociation < ::Nanoc::Core::Error
        def initialize(content_filenames, meta_filename)
          super("There are multiple content files (#{content_filenames.sort.join(', ')}) that could match the file containing metadata (#{meta_filename}).")
        end
      end
    end
  end
end
