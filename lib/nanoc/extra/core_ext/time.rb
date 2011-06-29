# encoding: utf-8

module Nanoc::Extra::TimeExtensions

  # @return [String] The time in an ISO-8601 date format.
  def to_iso8601_date
    self.strftime("%Y-%m-%d")
  end

  # @return [String] The time in an ISO-8601 time format.
  def to_iso8601_time
    self.getutc.strftime("%Y-%m-%dT%H:%M:%SZ")
  end

end

class Time
  include Nanoc::Extra::TimeExtensions
end
