# encoding: utf-8

module Nanoc::Extra::Checking
  # @api private
  class OutputDirNotFoundError < Nanoc::Int::Errors::Generic
    def initialize(directory_path)
      super("Unable to run check against output directory at “#{directory_path}”: directory does not exist.")
    end
  end

  # @api private
  class Check
    extend Nanoc::Int::PluginRegistry::PluginMethods

    attr_reader :site
    attr_reader :issues
    attr_reader :output_filenames

    def initialize(site)
      @site = site

      @issues = Set.new
      @output_filenames = []
    end

    def run
      raise NotImplementedError.new('Nanoc::Extra::Checking::Check subclasses must implement #run')
    end

    def add_issue(desc, params = {})
      subject  = params.fetch(:subject, nil)

      @issues << Issue.new(desc, subject, self.class)
    end

    def setup
      output_dir = @site.config[:output_dir]
      unless File.exist?(output_dir)
        raise Nanoc::Extra::Checking::OutputDirNotFoundError.new(output_dir)
      end
      @output_filenames = Dir[output_dir + '/**/*'].select { |f| File.file?(f) }
    end
  end
end
