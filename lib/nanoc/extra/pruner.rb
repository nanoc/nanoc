module Nanoc::Extra
  # Responsible for finding and deleting files in the site’s output directory
  # that are not managed by Nanoc.
  #
  # @api private
  class Pruner
    # @return [Nanoc::Int::Site] The site this pruner belongs to
    attr_reader :site

    # @param [Nanoc::Int::Site] site The site for which a pruner is created
    #
    # @param [Boolean] dry_run true if the files to be deleted
    #   should only be printed instead of actually deleted, false if the files
    #   should actually be deleted.
    #
    # @param [Enumerable<String>] exclude
    def initialize(site, dry_run: false, exclude: [])
      @site    = site
      @dry_run = dry_run
      @exclude = exclude
    end

    # Prunes all output files not managed by Nanoc.
    #
    # @return [void]
    def run
      require 'find'

      # Get compiled files
      # FIXME: requires #build_reps to have been called
      all_raw_paths = site.compiler.reps.flat_map { |r| r.raw_paths.values }
      compiled_files = all_raw_paths.flatten.compact.select { |f| File.file?(f) }

      # Get present files and dirs
      present_files = []
      present_dirs = []
      Find.find(site.config[:output_dir] + '/') do |f|
        present_files << f if File.file?(f)
        present_dirs << f if File.directory?(f)
      end

      # Remove stray files
      stray_files = (present_files - compiled_files)
      stray_files.each do |f|
        next if filename_excluded?(f)
        delete_file(f)
      end

      # Remove empty directories
      present_dirs.reverse_each do |dir|
        next if Dir.foreach(dir) { |n| break true if n !~ /\A\.\.?\z/ }
        next if filename_excluded?(dir)
        delete_dir(dir)
      end
    end

    # @param [String] filename The filename to check
    #
    # @return [Boolean] true if the given file is excluded, false otherwise
    def filename_excluded?(filename)
      pathname = Pathname.new(filename)
      @exclude.any? { |e| pathname.__nanoc_include_component?(e) }
    end

    protected

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
