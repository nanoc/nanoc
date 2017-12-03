# frozen_string_literal: true

module Nanoc::External
  class Filter < Nanoc::Filter
    identifier :external

    def run(content, params = {})
      cmd   = params.fetch(:exec)
      opts  = params.fetch(:options, [])

      cmd_with_opts = [cmd] + opts
      out = StringIO.new
      piper = Nanoc::Extra::Piper.new(stdout: out, stderr: $stderr)
      piper.run(cmd_with_opts, content)
      out.string
    end
  end
end
