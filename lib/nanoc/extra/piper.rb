# encoding: utf-8

require 'open3'

module Nanoc::Extra

  class Piper

    class Error < ::Nanoc::Errors::Generic

      def initialize(command, exit_code)
        @command   = command
        @exit_code = exit_code
      end

      def message
        "command exited with a nonzero status code #{@exit_code} (command: #{@command.join(' ')})"
      end

    end

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
        stdout_thread = Thread.new { @stdout << stdout.read }
        stderr_thread = Thread.new { @stderr << stderr.read }

        if input
          stdin << input
        end
        stdin.close

        stdout_thread.join
        stderr_thread.join

        exit_status = wait_thr.value
        if !exit_status.success?
          raise Error.new(cmd, exit_status.to_i)
        end
      end
    end

  end

end
