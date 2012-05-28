# encoding: utf-8

module Nanoc::Extra

  # Responsible for finding and deleting files in the site’s output directory
  # that are not managed by nanoc.
  class Pruner

    # @return [Nanoc::Site] The site this pruner belongs to  
    attr_reader :site

    # @param [Nanoc::Site] site The site for which a pruner is created
    #
    # @option params [Boolean] :dry_run (false) true if the files to be deleted
    #   should only be printed instead of actually deleted, false if the files
    #   should actually be deleted.
    def initialize(site, params={})
      @site    = site
      @dry_run = params.fetch(:dry_run) { false }
      @exclude = params.fetch(:exclude) { [] }
    end

    # Prunes all output files not managed by nanoc.
    #
    # @return [void]
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
      stray_files = (present_files - compiled_files)
      stray_files.each do |f|
        next if filename_excluded?(f)
        self.delete_file(f)
      end

      # Remove empty directories
      present_dirs.sort_by{ |d| -d.length }.each do |dir|
        next if Dir.foreach(dir) { |n| break true if n !~ /\A\.\.?\z/ }
        next if filename_excluded?(dir)
        self.delete_dir(dir)
      end
    end

  protected

    def filename_excluded?(f)
      pathname = Pathname.new(f)
      @exclude.any? { |e| pathname.include_component?(e) } 
    end

    def delete_file(file)
      if @dry_run
        puts file
      else
        Nanoc::CLI::Logger.instance.file(:high, :delete, file)
        FileUtils.rm(file)
      end
    end

    def delete_dir(dir)
      if @dry_run
        puts dir
      else
        Nanoc::CLI::Logger.instance.file(:high, :delete, dir)
        Dir.rmdir(dir)
      end
    end

  end

end
