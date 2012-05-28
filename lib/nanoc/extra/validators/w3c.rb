# encoding: utf-8

module Nanoc::Extra::Validators

  # @deprecated Use the Checking API or the `check` command instead
  class W3C

    def initialize(dir, types)
      @dir   = dir
      @types = types
    end

    def run
      Nanoc::CLI.run(%w( check html css ))
    end

  end

end
