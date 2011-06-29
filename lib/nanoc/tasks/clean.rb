# encoding: utf-8

module Nanoc::Tasks

  class Clean

    def initialize(site)
      @site = site
    end

    def run
      filenames.each do |filename|
        FileUtils.rm_f filename unless filename.nil?
      end
    end

  private

    def filenames
      @site.items.map do |item|
        item.reps.map do |rep|
          rep.raw_path
        end
      end.flatten
    end

  end

end
