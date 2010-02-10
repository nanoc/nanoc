# encoding: utf-8

module Nanoc3::Extra::TimeExtensions

  # @return [String] The time in an ISO-8601 date format.
  def to_iso8601_date
    self.strftime("%Y-%m-%d")
  end

  # @return [String] The time in an ISO-8601 time format.
  def to_iso8601_time
    self.gmtime.strftime("%Y-%m-%dT%H:%M:%SZ")
  end

end

class Time
  include Nanoc3::Extra::TimeExtensions
end
