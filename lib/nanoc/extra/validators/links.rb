# encoding: utf-8

module Nanoc::Extra::Validators

  # @deprecated Use the Checking API or the `check` command instead
  class Links

    def initialize(dir, index_filenames, params={})
      @include_internal = params.has_key?(:internal) && params[:internal]
      @include_external = params.has_key?(:external) && params[:external]
    end

    def run
      checkers = []
      checkers << 'ilinks' if options[:internal]
      checkers << 'elinks' if options[:external]
      Nanoc::CLI.run [ 'check', checkers ].flatten
    end

  end

end
