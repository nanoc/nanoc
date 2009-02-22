require 'test/helper'

class Nanoc::Filters::ERBTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    # Create filter
    filter = ::Nanoc::Filters::ERB.new({ :location => 'a cheap motel' })

    # Run filter
    result = filter.run('<%= "I was hiding in #{@location}." %>')
    assert_equal('I was hiding in a cheap motel.', result)
  end

  def test_filter_error_page
    # Create item and item rep
    item = MiniTest::Mock.new
    item.expect(:path, '/foo/bar/baz/')
    item_rep = MiniTest::Mock.new
    item_rep.expect(:name, :quux)

    # Create filter
    filter = ::Nanoc::Filters::ERB.new({
      :_obj     => item,
      :_obj_rep => item_rep,
      :page     => MiniTest::Mock.new,
      :location => 'a cheap motel'
    })

    # Run filter
    raised = false
    begin
      filter.run('<%= this isn\'t really ruby so it\'ll break, muahaha %>')
    rescue SyntaxError => e
      assert_match 'page /foo/bar/baz/ (rep quux)', e.backtrace[0]
      raised = true
    end
    assert raised
  end

  def test_filter_error_asset
    # Create item and item rep
    item = MiniTest::Mock.new
    item.expect(:path, '/foo/bar/baz/')
    item_rep = MiniTest::Mock.new
    item_rep.expect(:name, :quux)

    # Create filter
    filter = ::Nanoc::Filters::ERB.new({
      :_obj     => item,
      :_obj_rep => item_rep,
      :asset    => MiniTest::Mock.new,
      :location => 'a cheap motel'
    })

    # Run filter
    raised = false
    begin
      filter.run('<%= this isn\'t really ruby so it\'ll break, muahaha %>')
    rescue SyntaxError => e
      assert_match 'asset /foo/bar/baz/ (rep quux)', e.backtrace[0]
      raised = true
    end
    assert raised
  end

end
