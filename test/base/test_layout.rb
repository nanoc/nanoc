# frozen_string_literal: true

require 'helper'

class Nanoc::Int::LayoutTest < Nanoc::TestCase
  def test_initialize
    # Make sure attributes are cleaned
    layout = Nanoc::Int::Layout.new('content', { 'foo' => 'bar' }, '/foo')
    assert_equal({ foo: 'bar' }, layout.attributes)
  end

  def test_attributes
    layout = Nanoc::Int::Layout.new('content', { 'foo' => 'bar' }, '/foo/')
    assert_equal({ foo: 'bar' }, layout.attributes)
  end
end
