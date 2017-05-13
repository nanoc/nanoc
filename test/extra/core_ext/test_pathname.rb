# frozen_string_literal: true

require 'helper'

class Nanoc::Extra::CoreExtPathnameTest < Nanoc::TestCase
  def test_components
    assert_equal %w[/ a bb ccc dd e], Pathname.new('/a/bb/ccc/dd/e').__nanoc_components
  end

  def test_include_component
    assert Pathname.new('/home/ddfreyne/').__nanoc_include_component?('ddfreyne')
    refute Pathname.new('/home/ddfreyne/').__nanoc_include_component?('acid')
  end
end
