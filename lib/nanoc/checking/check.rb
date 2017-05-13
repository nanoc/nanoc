# frozen_string_literal: true

module Nanoc::Checking
  # @api private
  class OutputDirNotFoundError < Nanoc::Int::Errors::Generic
    def initialize(directory_path)
      super("Unable to run check against output directory at “#{directory_path}”: directory does not exist.")
    end
  end

  # @api private
  class Check < Nanoc::Int::Context
    extend DDPlugin::Plugin

    attr_reader :issues

    def self.create(site)
      output_dir = site.config[:output_dir]
      unless File.exist?(output_dir)
        raise Nanoc::Checking::OutputDirNotFoundError.new(output_dir)
      end
      output_filenames = Dir[output_dir + '/**/*'].select { |f| File.file?(f) }

      # FIXME: ugly
      view_context = site.compiler.compilation_context.create_view_context(Nanoc::Int::DependencyTracker::Null.new)

      context = {
        items: Nanoc::PostCompileItemCollectionView.new(site.items, view_context),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, view_context),
        config: Nanoc::ConfigView.new(site.config, view_context),
        output_filenames: output_filenames,
      }

      new(context)
    end

    def initialize(context)
      super(context)

      @issues = Set.new
    end

    def run
      raise NotImplementedError.new('Nanoc::Checking::Check subclasses must implement #run')
    end

    def add_issue(desc, subject: nil)
      @issues << Issue.new(desc, subject, self.class)
    end
  end
end
