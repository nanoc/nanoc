# frozen_string_literal: true

module Nanoc::External
  class Filter < Nanoc::Filter
    identifier :external

    def run(content, params = {})
      cmd   = params.fetch(:exec)
      opts  = params.fetch(:options, [])

      command = TTY::Command.new(printer: :null)
      command.run(cmd, *opts, input: content).out
    end
  end
end
