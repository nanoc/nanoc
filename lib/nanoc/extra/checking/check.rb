# encoding: utf-8

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
        items: Nanoc::ItemCollectionView.new(site.items),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts),
        config: Nanoc::ConfigView.new(site.config),
        site: Nanoc::SiteView.new(site), # TODO: remove me
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

    def add_issue(desc, params = {})
      subject = params.fetch(:subject, nil)

      @issues << Issue.new(desc, subject, self.class)
    end
  end
end
