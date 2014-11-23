# encoding: utf-8

module Nanoc::Extra::Checking
  class OutputDirNotFoundError < Nanoc::Errors::Generic
    def initialize(directory_path)
      super("Unable to run check against output directory at “#{directory_path}”: directory does not exist.")
    end
  end

  class Check
    extend Nanoc::PluginRegistry::PluginMethods

    attr_reader :site
    attr_reader :issues

    def initialize(site)
      @site   = site
      @issues = Set.new
    end

    def run
      raise NotImplementedError.new('Nanoc::Extra::Checking::Check subclasses must implement #run')
    end

    def add_issue(desc, params = {})
      subject  = params.fetch(:subject, nil)

      @issues << Issue.new(desc, subject, self.class)
    end

    def output_filenames
      output_dir = @site.config[:output_dir]
      unless File.exist?(output_dir)
        raise Nanoc::Extra::Checking::OutputDirNotFoundError.new(output_dir)
      end
      Dir[output_dir + '/**/*'].select { |f| File.file?(f) }
    end
  end
end
