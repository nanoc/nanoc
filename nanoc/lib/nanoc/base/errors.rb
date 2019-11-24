# frozen_string_literal: true

module Nanoc
  module Int
    # Module that contains all Nanoc-specific errors.
    #
    # @api private
    module Errors
      class AmbiguousMetadataAssociation < ::Nanoc::Core::Error
        def initialize(content_filenames, meta_filename)
          super("There are multiple content files (#{content_filenames.sort.join(', ')}) that could match the file containing metadata (#{meta_filename}).")
        end
      end
    end
  end
end
