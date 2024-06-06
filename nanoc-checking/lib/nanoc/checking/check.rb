# frozen_string_literal: true

module Nanoc
  module Checking
    # @api private
    class OutputDirNotFoundError < ::Nanoc::Core::Error
      def initialize(directory_path)
        super("Unable to run check against output directory at “#{directory_path}”: directory does not exist.")
      end
    end

    # @api private
    class Check < Nanoc::Core::Context
      extend DDPlugin::Plugin

      prepend MemoWise

      attr_reader :issues

      def self.define(ident, &block)
        klass = Class.new(self) { identifier(ident) }
        klass.send(:define_method, :run) do
          instance_exec(&block)
        end
      end

      def self.create(site)
        output_dir = site.config.output_dir
        unless File.exist?(output_dir)
          raise Nanoc::Checking::OutputDirNotFoundError.new(output_dir)
        end

        output_filenames = Dir[output_dir + '/**/*'].select { |f| File.file?(f) }

        # FIXME: ugly
        compiler = Nanoc::Core::Compiler.new_for(site)
        res = compiler.run_until_reps_built
        reps = res.fetch(:reps)
        view_context =
          Nanoc::Core::ViewContextForShell.new(
            items: site.items,
            reps:,
          )

        context = {
          items: Nanoc::Core::PostCompileItemCollectionView.new(site.items, view_context),
          layouts: Nanoc::Core::LayoutCollectionView.new(site.layouts, view_context),
          config: Nanoc::Core::ConfigView.new(site.config, view_context),
          output_filenames:,
        }

        new(context)
      end

      def initialize(context)
        super

        @issues = Set.new
      end

      def run
        raise NotImplementedError.new('Nanoc::Checking::Check subclasses must implement #run')
      end

      def add_issue(desc, subject: nil)
        # Simplify subject
        # FIXME: do not depend on working directory
        if subject&.start_with?(Dir.getwd)
          subject = subject[(Dir.getwd.size + 1)..subject.size]
        end

        @issues << Issue.new(desc, subject, self.class)
      end

      # @private
      def output_filenames
        super.reject { |f| excluded_patterns.any? { |pat| pat.match?(f) } }
      end

      # @private
      def excluded_patterns
        @config
          .fetch(:checks, {})
          .fetch(:all, {})
          .fetch(:exclude_files, [])
          .map { |pattern| Regexp.new(pattern) }
      end
      memo_wise :excluded_patterns

      # @private
      def output_html_filenames
        output_filenames.select { |f| File.extname(f) =~ /\A\.x?html?\z/ }
      end
    end
  end
end
