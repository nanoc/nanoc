# frozen_string_literal: true

module Nanoc
  # @api private
  module Telemetry
    def self.new
      Registry.new
    end
  end
end

require_relative 'telemetry/counter'
require_relative 'telemetry/summary'

require_relative 'telemetry/labelled_counter'
require_relative 'telemetry/labelled_summary'

require_relative 'telemetry/registry'
require_relative 'telemetry/stopwatch'

require_relative 'telemetry/table'
