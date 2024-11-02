# frozen_string_literal: true

module Nanoc
  module Core
    class TempFilenameFactory
      # @return [String] The root directory for all temporary filenames
      attr_reader :root_dir

      # @return [Nanoc::Core::TempFilenameFactory] A common instance
      def self.instance
        @_instance ||= new
      end

      def initialize
        @counts = {}
        @root_dir = Dir.mktmpdir('nanoc')
        @mutex = Mutex.new
      end

      # @param [String] prefix A string prefix to include in the temporary
      #   filename, often the type of filename being provided.
      #
      # @return [String] A new unused filename
      def create(prefix)
        count = nil
        @mutex.synchronize do
          count = @counts.fetch(prefix, 0)
          @counts[prefix] = count + 1
        end

        dirname  = File.join(@root_dir, prefix)
        filename = File.join(@root_dir, prefix, count.to_s)

        FileUtils.mkdir_p(dirname)

        filename
      end

      # @param [String] prefix A string prefix that indicates which temporary
      #   filenames should be deleted.
      #
      # @return [void]
      def cleanup(prefix)
        path = File.join(@root_dir, prefix)

        FileUtils.rm_rf(path)

        @counts.delete(prefix)

        if @counts.empty? && File.directory?(@root_dir)
          FileUtils.rm_rf(@root_dir)
        end
      end
    end
  end
end
