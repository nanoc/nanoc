# encoding: utf-8

require 'tmpdir'

module Nanoc

  class TempPathRegistry

    def self.instance
      @instance ||= new
    end

    def self.cleanup(prefix)
      instance.cleanup(prefix)
    end

    def self.new_path(prefix)
      instance.new_path(prefix)
    end

    def initialize
      @counts = {}
      @root_path = Dir.mktmpdir('nanoc')
    end

    def new_path(prefix)
      count = @counts.fetch(prefix, 0)
      @counts[prefix] = count + 1

      dirname  = File.join(@root_path, prefix)
      filename = File.join(@root_path, prefix, count.to_s)

      FileUtils.mkdir_p(dirname)

      filename
    end

    def cleanup(prefix)
      path = File.join(@root_path, prefix)
      if File.exist?(path)
        FileUtils.remove_entry_secure(path)
      end

      @counts.delete(prefix)
    end

  end

end
