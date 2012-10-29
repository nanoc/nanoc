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
      types = @types.dup
      args << 'html' if types.delete(:html)
      args << 'css'  if types.delete(:css)
      unless types.empty?
        raise Nanoc::Errors::GenericTrivial, "unknown type(s) specified: #{types.join(', ')}"
      end

      Nanoc::CLI.run([ 'check', args ].flatten)
    end

  end

end
