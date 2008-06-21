require 'helper'

class Nanoc::Extensions::LinkToTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Extensions::LinkTo

  def test_link_to_with_path
    # Check
    assert_equal(
      '<a href="/foo/">Foo</a>',
      link_to('/foo/', 'Foo')
    )
  end

  def test_link_to_with_rep
    # Create rep
    rep = mock
    rep.expects(:path).returns('/bar/')

    # Check
    assert_equal(
      '<a href="/bar/">Bar</a>',
      link_to(rep, 'Bar')
    )
  end

  def test_link_to_with_attributes
    # Check
    assert_equal(
      '<a title="Dis mai foo!" href="/foo/">Foo</a>',
      link_to('/foo/', 'Foo', :title => 'Dis mai foo!')
    )
  end

  def test_link_to_unless_current_current
    # Create page
    @page_rep = mock
    @page_rep.expects(:path).at_least_once.returns('/foo/')

    # Check
    assert_equal(
      '<span class="active" title="You\'re here.">Bar</span>',
      link_to_unless_current(@page_rep, 'Bar')
    )
  ensure
    @page = nil
  end

  def test_link_to_unless_current_not_current
    # Create page
    @page_rep = mock
    @page_rep.expects(:path).at_least_once.returns('/foo/')

    # Check
    assert_equal(
      '<a href="/abc/xyz/">Bar</a>',
      link_to_unless_current('/abc/xyz/', 'Bar')
    )
  end

end
