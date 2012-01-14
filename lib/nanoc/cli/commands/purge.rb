# encoding: utf-8

usage       'purge'
summary     'removes files not managed by nanoc from the output directory'
description <<-EOS
Find all files in the output directory that do not correspond to an item managed by nanoc and remove them. Since this is a hazardous operation, an additional --yes flag is needed as confirmation.
EOS

flag :y, :yes,       'confirm deletion' # TODO implement
flag :n, :'dry-run', 'print files to be deleted instead of actually deleting them' # TODO implement

run do |opts, args, cmd|
  Nanoc::CLI::Commands::Purge.call(opts, args, cmd)
end

module Nanoc::CLI::Commands

  class Purge < ::Nanoc::CLI::Command

    def run
      require 'find'

      # Get compiled files
      compiled_files = self.site.items.map do |item|
        item.reps.map do |rep|
          rep.raw_path
        end
      end.flatten.compact.select { |f| File.file?(f) }

      # Get present files and dirs
      present_files_and_dirs = Set.new
      Find.find(self.site.config[:output_dir]) do |f|
        present_files_and_dirs << f
      end
      present_files = present_files_and_dirs.select { |f| File.file?(f) }
      present_dirs  = present_files_and_dirs.select { |f| File.directory?(f) }

      # Remove stray files
      stray_files = present_files - compiled_files
      stray_files.each do |f|
        Nanoc3::CLI::Logger.instance.file(:high, :delete, f)
        FileUtils.rm(f)
      end

      # Remove empty directories
      present_dirs.sort_by{ |d| -d.length }.each do |dir|
        next if Dir.foreach(dir) { |n| break true if n !~ /\A\.\.?\z/ }

        Nanoc3::CLI::Logger.instance.file(:high, :delete, dir)
        Dir.rmdir(dir)
      end
    end
  end
end
