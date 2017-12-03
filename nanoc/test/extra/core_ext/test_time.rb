# frozen_string_literal: true

require 'helper'

class Nanoc::ExtraCoreExtTimeTest < Nanoc::TestCase
  def test___nanoc_to_iso8601_date_utc
    assert_equal('2008-05-19', Time.utc(2008, 5, 19, 14, 20, 0, 0).__nanoc_to_iso8601_date)
  end

  def test___nanoc_to_iso8601_date_non_utc
    assert_equal('2008-05-18', Time.new(2008, 5, 19, 0, 0, 0, '+02:00').__nanoc_to_iso8601_date)
  end

  def test___nanoc_to_iso8601_time
    assert_equal('2008-05-19T14:20:00Z', Time.utc(2008, 5, 19, 14, 20, 0, 0).__nanoc_to_iso8601_time)
  end
end
