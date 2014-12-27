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
    def initialize(params = {})
      @stdout = params.fetch(:stdout, $stdout)
    end

    # @param [Array<String>] cmd
    #
    # @param [String, nil] input
    #
    # @raises Nanoc::Extra::Piper::Error when the command fails
    def run(cmd, input)
      IO.popen(cmd.join(' '), 'r+') do |io|
        if input
          io.puts input
        end
        io.close_write
        while stdout = io.gets
          @stdout << stdout
        end
      end
      unless $?.success?
        raise Error.new(cmd, $?.to_i)
      end
    end
  end
end
