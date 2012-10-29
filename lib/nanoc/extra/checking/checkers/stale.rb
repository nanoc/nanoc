# encoding: utf-8

module Nanoc::Extra::Checking::Checkers

  class Stale < ::Nanoc::Extra::Checking::Checker

    def run
      require 'set'
      item_rep_paths = Set.new(@site.items.collect { |i| i.reps }.flatten.collect { |r| r.raw_path })
      self.output_filenames.each do |f|
        if !item_rep_paths.include?(f)
          self.add_issue(
            "file without matching item",
            :subject  => f)
        end
      end
    end

  end

end


