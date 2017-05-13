# frozen_string_literal: true

# @api private
module Nanoc::Extra::TimeExtensions
  # @return [String] The time in an ISO-8601 date format.
  def __nanoc_to_iso8601_date
    getutc.strftime('%Y-%m-%d')
  end

  # @return [String] The time in an ISO-8601 time format.
  def __nanoc_to_iso8601_time
    getutc.strftime('%Y-%m-%dT%H:%M:%SZ')
  end
end

# @api private
class Time
  include Nanoc::Extra::TimeExtensions
end
