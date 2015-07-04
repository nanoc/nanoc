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

      context = {
        items: Nanoc::ItemCollectionView.new(site.items, nil),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, nil),
        config: Nanoc::ConfigView.new(site.config, nil),
        site: Nanoc::SiteView.new(site, nil), # TODO: remove me
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
