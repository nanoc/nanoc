# encoding: utf-8

module Nanoc::Extra::Validators

  # @deprecated Use the Checking API or the `check` command instead
  class W3C

    def initialize(dir, types)
      @dir   = dir
      @types = types
    end

    def run
      args = []
      args << 'html' if @types.include?(:html)
      args << 'css'  if @types.include?(:css)
      Nanoc::CLI.run([ 'check', args ].flatten)
    end

  end

end
