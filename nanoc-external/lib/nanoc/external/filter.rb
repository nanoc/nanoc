# frozen_string_literal: true

module Nanoc::External
  class Filter < Nanoc::Filter
    identifier :external

    def run(content, params = {})
      debug = params.fetch(:debug, false)
      cmd   = params.fetch(:exec)
      opts  = params.fetch(:options, [])

      if cmd.nil?
        raise Nanoc::Errors::GenericTrivial.new('nanoc-external: missing :exec argument')
      end

      cmd_with_opts = [cmd] + opts
      odebug(cmd_with_opts.join(' ')) if debug
      out = StringIO.new
      piper = Nanoc::Extra::Piper.new(stdout: out, stderr: $stderr)
      piper.run(cmd_with_opts, content)
      odebug(out.string) if debug
      out.string
    end

    private

    def odebug(msg)
      msg.each_line { |l| puts "\033[1;31mDEBUG:\033[0m #{l}" }
    end
  end
end
