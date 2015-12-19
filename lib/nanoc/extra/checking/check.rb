module Nanoc::Extra::Checking
  # @api private
  class OutputDirNotFoundError < Nanoc::Int::Errors::Generic
    def initialize(directory_path)
      super("Unable to run check against output directory at “#{directory_path}”: directory does not exist.")
    end
  end

  # @api private
  class Check < Nanoc::Int::Context
    extend Nanoc::Int::PluginRegistry::PluginMethods

    attr_reader :issues

    def self.create(site)
      output_dir = site.config[:output_dir]
      unless File.exist?(output_dir)
        raise Nanoc::Extra::Checking::OutputDirNotFoundError.new(output_dir)
      end
      output_filenames = Dir[output_dir + '/**/*'].select { |f| File.file?(f) }

      # FIXME: ugly
      view_context = site.compiler.create_view_context(Nanoc::Int::DependencyTracker::Null.new)

      context = {
        items: Nanoc::ItemCollectionWithRepsView.new(site.items, view_context),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, view_context),
        config: Nanoc::ConfigView.new(site.config, view_context),
        site: Nanoc::SiteView.new(site, view_context), # TODO: remove me
        output_filenames: output_filenames,
      }

      new(context)
    end

    def initialize(context)
      super(context)

      @issues = Set.new
    end

    def run
      raise NotImplementedError.new('Nanoc::Extra::Checking::Check subclasses must implement #run')
    end

    def add_issue(desc, subject: nil)
      @issues << Issue.new(desc, subject, self.class)
    end
  end
end
