# encoding: utf-8

module Nanoc::Extra::Validators

  # @deprecated Use the Checking API or the `check` command instead
  class Links

    def initialize(dir, index_filenames, params = {})
      @include_internal = params.key?(:internal) && params[:internal]
      @include_external = params.key?(:external) && params[:external]
    end

    def run
      checks = []
      checks << 'ilinks' if options[:internal]
      checks << 'elinks' if options[:external]
      Nanoc::CLI.run [ 'check', checks ].flatten
    end

  end

end
