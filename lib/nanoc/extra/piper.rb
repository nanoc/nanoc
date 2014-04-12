# encoding: utf-8

require 'open3'

module Nanoc::Extra

  class Piper

    # @option [IO] :stdout ($stdout)
    # @option [IO] :stderr ($stderr)
    def initialize(params={})
      @stdout = params.fetch(:stdout, $stdout)
      @stderr = params.fetch(:stderr, $stderr)
    end

    # @param [Array<String>] cmd
    #
    # @param [String, nil] input
    def run(cmd, input)
      Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thr|
        # TODO write to stdin
        stdin.close

        Thread.new { @stdout << stdout.read }
        Thread.new { @stderr << stderr.read }

        exit_status = wait_thr.value
        if !exit_status.success?
          raise Nanoc::Errors::Generic,
            "command exited with a nonzero status code #{exit_status.to_i} (command: #{cmd.join(' ')})"
        end
      end
    end

  end

end
