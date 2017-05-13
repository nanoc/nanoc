# frozen_string_literal: true

require 'open3'

module Nanoc::Extra
  # @api private
  class Piper
    class Error < ::Nanoc::Int::Errors::Generic
      def initialize(command, exit_code)
        @command   = command
        @exit_code = exit_code
      end

      def message
        "command exited with a nonzero status code #{@exit_code} (command: #{@command.join(' ')})"
      end
    end

    # @param [IO] stdout
    # @param [IO] stderr
    def initialize(stdout: $stdout, stderr: $stderr)
      @stdout = stdout
      @stderr = stderr
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
        unless exit_status.success?
          raise Error.new(cmd, exit_status.to_i)
        end
      end
    end
  end
end
