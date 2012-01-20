# encoding: utf-8

class Nanoc::Extra::CoreExtPathnameTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_components
    assert_equal %w( / a bb ccc dd e ), Pathname.new('/a/bb/ccc/dd/e').components
  end

  def test_include_component
    assert Pathname.new('/home/ddfreyne/').include_component?('ddfreyne')
    refute Pathname.new('/home/ddfreyne/').include_component?('acid')
  end

end

