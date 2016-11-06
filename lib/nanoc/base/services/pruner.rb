module Nanoc
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
      @exclude = Set.new(exclude)

      # TODO: do not pass in site, but config + item reps
    end

    # Prunes all output files not managed by Nanoc.
    #
    # @return [void]
    def run
      require 'find'

      return unless File.directory?(site.config[:output_dir])

      # Get compiled files
      # FIXME: requires #build_reps to have been called
      all_raw_paths = site.compiler.reps.flat_map { |r| r.raw_paths.values }
      compiled_files = all_raw_paths.flatten.compact.select { |f| File.file?(f) }

      # Get present files and dirs
      present_files, present_dirs = files_and_dirs_in(site.config[:output_dir] + '/')

      # Remove stray files
      stray_files = (present_files - compiled_files)
      stray_files.each do |f|
        delete_file(f) unless exclude?(f)
      end

      # Remove empty directories
      present_dirs.reverse_each do |dir|
        next if Dir.foreach(dir) { |n| break true if n !~ /\A\.\.?\z/ }
        next if exclude?(dir)
        delete_dir(dir)
      end
    end

    def exclude?(component)
      @exclude.include?(component)
    end

    # @param [String] filename The filename to check
    #
    # @return [Boolean] true if the given file is excluded, false otherwise
    def filename_excluded?(filename)
      pathname = Pathname.new(filename)
      @exclude.any? { |e| pathname.__nanoc_include_component?(e) }
    end

    # @api private
    def files_and_dirs_in(dir)
      present_files = []
      present_dirs = []

      Find.find(dir) do |f|
        basename = File.basename(f)

        case File.ftype(f)
        when 'file'.freeze
          unless exclude?(basename)
            present_files << f
          end
        when 'directory'.freeze
          if exclude?(basename)
            Find.prune
          else
            present_dirs << f
          end
        end
      end

      [present_files, present_dirs]
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
      # TODO: deduplicate code

      if @dry_run
        puts dir
      else
        Nanoc::CLI::Logger.instance.file(:high, :delete, dir)
        Dir.rmdir(dir)
      end
    end
  end
end
