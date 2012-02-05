# encoding: utf-8

class Nanoc::Filters::ERBTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter_with_instance_variable
    # Create filter
    filter = ::Nanoc::Filters::ERB.new({ :location => 'a cheap motel' })

    # Run filter
    result = filter.run('<%= "I was hiding in #{@location}." %>')
    assert_equal('I was hiding in a cheap motel.', result)
  end

  def test_filter_with_instance_method
    # Create filter
    filter = ::Nanoc::Filters::ERB.new({ :location => 'a cheap motel' })

    # Run filter
    result = filter.run('<%= "I was hiding in #{location}." %>')
    assert_equal('I was hiding in a cheap motel.', result)
  end

  def test_filter_error_item
    # Create item and item rep
    item = MiniTest::Mock.new
    item.expect(:identifier, '/foo/bar/baz/')
    item_rep = MiniTest::Mock.new
    item_rep.expect(:name, :quux)

    # Create filter
    filter = ::Nanoc::Filters::ERB.new({
      :item     => item,
      :item_rep => item_rep,
      :location => 'a cheap motel'
    })

    # Run filter
    raised = false
    begin
      filter.run('<%= this isn\'t really ruby so it\'ll break, muahaha %>')
    rescue SyntaxError => e
      e.message =~ /(.+?):\d+: /
      assert_match 'item /foo/bar/baz/ (rep quux)', $1
      raised = true
    end
    assert raised
  end

  def test_filter_with_yield
    # Create filter
    filter = ::Nanoc::Filters::ERB.new({ :content => 'a cheap motel' })

    # Run filter
    result = filter.run('<%= "I was hiding in #{yield}." %>')
    assert_equal('I was hiding in a cheap motel.', result)
  end

  def test_filter_with_yield_without_content
    # Create filter
    filter = ::Nanoc::Filters::ERB.new({ :location => 'a cheap motel' })

    # Run filter
    assert_raises LocalJumpError do
      filter.run('<%= "I was hiding in #{yield}." %>')
    end
  end

  def test_safe_level
    # Set up
    filter = ::Nanoc::Filters::ERB.new
    File.open('moo', 'w') { |io| io.write("one miiillion dollars") }

    # Without
    res = filter.run('<%= File.read("moo") %>', :safe_level => nil)
    assert_equal 'one miiillion dollars', res

    # With
    assert_raises(SecurityError) do
      res = filter.run('<%= File.read("moo") %>', :safe_level => 4)
    end
  end

  def test_trim_mode
    # Set up
    filter = ::Nanoc::Filters::ERB.new({ :location => 'a cheap motel' })
    $trim_mode_works = false

    # Without
    filter.run('% $trim_mode_works = true')
    refute $trim_mode_works

    # With
    filter.run('% $trim_mode_works = true', :trim_mode => '%')
    assert $trim_mode_works
  end

  def test_locals
    filter = ::Nanoc::Filters::ERB.new
    result = filter.run('<%= @local %>', :locals => { :local => 123 })
    assert_equal '123', result
  end

end
