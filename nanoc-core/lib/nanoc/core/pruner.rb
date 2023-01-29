# frozen_string_literal: true

module Nanoc
  module Core
    # Responsible for finding and deleting files in the site’s output directory
    # that are not managed by Nanoc.
    class Pruner
      include Nanoc::Core::ContractsSupport

      contract Nanoc::Core::Configuration, Nanoc::Core::ItemRepRepo, C::KeywordArgs[dry_run: C::Optional[C::Bool], exclude: C::Optional[C::IterOf[String]]] => C::Any
      def initialize(config, reps, dry_run: false, exclude: [])
        @config  = config
        @reps    = reps
        @dry_run = dry_run
        @exclude = Set.new(exclude)
      end

      def run
        return unless File.directory?(@config.output_dir)

        compiled_files = @reps.flat_map { |r| r.raw_paths.values.flatten }.compact
        present_files, present_dirs = files_and_dirs_in(@config.output_dir + '/')

        remove_stray_files(present_files, compiled_files)
        remove_empty_directories(present_dirs)
      end

      contract String => C::Bool
      def filename_excluded?(filename)
        pathname = Pathname.new(strip_output_dir(filename))
        @exclude.any? { |e| pathname_components(pathname).include?(e) }
      end

      contract String => String
      def strip_output_dir(filename)
        if filename.start_with?(@config.output_dir)
          filename[@config.output_dir.size..]
        else
          filename
        end
      end

      contract Pathname => C::ArrayOf[String]
      def pathname_components(pathname)
        components = []
        tmp = pathname
        loop do
          old = tmp
          components << File.basename(tmp)
          tmp = File.dirname(tmp)
          break if old == tmp
        end
        components.reverse
      end

      contract C::ArrayOf[String], C::ArrayOf[String] => self
      # @api private
      def remove_stray_files(present_files, compiled_files)
        (present_files - compiled_files).each do |f|
          delete_file(f) unless filename_excluded?(f)
        end
        self
      end

      contract C::ArrayOf[String] => self
      # @api private
      def remove_empty_directories(present_dirs)
        present_dirs.reverse_each do |dir|
          next if Dir.foreach(dir) { |n| break true if n !~ /\A\.\.?\z/ }
          next if filename_excluded?(dir)

          delete_dir(dir)
        end
        self
      end

      contract String => C::ArrayOf[C::ArrayOf[String]]
      # @api private
      def files_and_dirs_in(dir)
        present_files = []
        present_dirs = []

        expanded_dir = File.expand_path(dir)

        Find.find(dir) do |f|
          case File.ftype(f)
          when 'file'
            unless filename_excluded?(f)
              present_files << f
            end
          when 'directory'
            if filename_excluded?(f)
              Find.prune
            elsif expanded_dir != File.expand_path(f)
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
          Nanoc::Core::NotificationCenter.post(:file_listed_for_pruning, thing)
        else
          Nanoc::Core::NotificationCenter.post(:file_pruned, thing)
          yield
        end
      end
    end
  end
end
