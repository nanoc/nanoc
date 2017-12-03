# frozen_string_literal: true

class Nanoc::DataSources::Filesystem < Nanoc::DataSource
  # @api private
  module Errors
    class Generic < ::Nanoc::Error
    end

    class BinaryLayout < Generic
      def initialize(content_filename)
        super("The layout file '#{content_filename}' is a binary file, but layouts can only be textual")
      end
    end

    class MultipleMetaFiles < Generic
      def initialize(meta_filenames, basename)
        super("Found #{meta_filenames.size} meta files for #{basename}; expected 0 or 1")
      end
    end

    class MultipleContentFiles < Generic
      def initialize(content_filenames, basename)
        super("Found #{content_filenames.size} content files for #{basename}; expected 0 or 1")
      end
    end

    class InvalidFormat < Generic
      def initialize(content_filename)
        super("The file '#{content_filename}' appears to start with a metadata section (three or five dashes at the top) but it does not seem to be in the correct format.")
      end
    end

    class UnparseableMetadata < Generic
      def initialize(filename, error)
        super("Could not parse metadata for #{filename}: #{error.message}")
      end
    end

    class InvalidMetadata < Generic
      def initialize(filename, klass)
        super("The file #{filename} has invalid metadata (expected key-value pairs, found #{klass} instead)")
      end
    end

    class InvalidEncoding < Generic
      def initialize(filename, encoding)
        super("Could not read #{filename} because the file is not valid #{encoding}.")
      end
    end

    class FileUnreadable < Generic
      def initialize(filename, error)
        super("Could not read #{filename}: #{error.inspect}")
      end
    end
  end
end
