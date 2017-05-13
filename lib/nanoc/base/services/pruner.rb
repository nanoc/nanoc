# frozen_string_literal: true

require 'find'

module Nanoc
  # Responsible for finding and deleting files in the site’s output directory
  # that are not managed by Nanoc.
  #
  # @api private
  class Pruner
    # @param [Nanoc::Int::Configuration] config
    #
    # @param [Nanoc::Int::ItemRepRepo] reps
    #
    # @param [Boolean] dry_run true if the files to be deleted
    #   should only be printed instead of actually deleted, false if the files
    #   should actually be deleted.
    #
    # @param [Enumerable<String>] exclude
    def initialize(config, reps, dry_run: false, exclude: [])
      @config  = config
      @reps    = reps
      @dry_run = dry_run
      @exclude = Set.new(exclude)
    end

    # Prunes all output files not managed by Nanoc.
    #
    # @return [void]
    def run
      return unless File.directory?(@config[:output_dir])

      compiled_files = @reps.flat_map { |r| r.raw_paths.values.flatten }.compact
      present_files, present_dirs = files_and_dirs_in(@config[:output_dir] + '/')

      remove_stray_files(present_files, compiled_files)
      remove_empty_directories(present_dirs)
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
    def remove_stray_files(present_files, compiled_files)
      (present_files - compiled_files).each do |f|
        delete_file(f) unless exclude?(f)
      end
    end

    # @api private
    def remove_empty_directories(present_dirs)
      present_dirs.reverse_each do |dir|
        next if Dir.foreach(dir) { |n| break true if n !~ /\A\.\.?\z/ }
        next if exclude?(dir)
        delete_dir(dir)
      end
    end

    # @api private
    def files_and_dirs_in(dir)
      present_files = []
      present_dirs = []

      Find.find(dir) do |f|
        basename = File.basename(f)

        case File.ftype(f)
        when 'file'
          unless exclude?(basename)
            present_files << f
          end
        when 'directory'
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
      log_delete_and_run(file) { FileUtils.rm(file) }
    end

    def delete_dir(dir)
      log_delete_and_run(dir) { Dir.rmdir(dir) }
    end

    def log_delete_and_run(thing)
      if @dry_run
        puts thing
      else
        Nanoc::CLI::Logger.instance.file(:high, :delete, thing)
        yield
      end
    end
  end
end
