# frozen_string_literal: true

require 'tmpdir'

module Nanoc::Int
  # @api private
  class TempFilenameFactory
    # @return [String] The root directory for all temporary filenames
    attr_reader :root_dir

    # @return [Nanoc::Int::TempFilenameFactory] A common instance
    def self.instance
      @instance ||= new
    end

    def initialize
      @counts = {}
      @root_dir = Dir.mktmpdir('nanoc')
    end

    # @param [String] prefix A string prefix to include in the temporary
    #   filename, often the type of filename being provided.
    #
    # @return [String] A new unused filename
    def create(prefix)
      count = @counts.fetch(prefix, 0)
      @counts[prefix] = count + 1

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
      if File.exist?(path)
        FileUtils.rm_rf(path)
      end

      @counts.delete(prefix)

      if @counts.empty? && File.directory?(@root_dir)
        FileUtils.rm_rf(@root_dir)
      end
    end
  end
end
