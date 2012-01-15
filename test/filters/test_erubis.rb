# encoding: utf-8

class Nanoc::Filters::ErubisTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter_with_instance_variable
    if_have 'erubis' do
      # Create filter
      filter = ::Nanoc::Filters::Erubis.new({ :location => 'a cheap motel' })

      # Run filter
      result = filter.run('<%= "I was hiding in #{@location}." %>')
      assert_equal('I was hiding in a cheap motel.', result)
    end
  end

  def test_filter_with_instance_method
    if_have 'erubis' do
      # Create filter
      filter = ::Nanoc::Filters::Erubis.new({ :location => 'a cheap motel' })

      # Run filter
      result = filter.run('<%= "I was hiding in #{location}." %>')
      assert_equal('I was hiding in a cheap motel.', result)
    end
  end

  def test_filter_error
    if_have 'erubis' do
      # Create filter
      filter = ::Nanoc::Filters::Erubis.new

      # Run filter
      raised = false
      begin
        filter.run('<%= this isn\'t really ruby so it\'ll break, muahaha %>')
      rescue SyntaxError => e
        e.message =~ /(.+?):\d+: /
        assert_match '?', $1
        raised = true
      end
      assert raised
    end
  end

  def test_filter_with_yield
    if_have 'erubis' do
      # Create filter
      filter = ::Nanoc::Filters::Erubis.new({ :content => 'a cheap motel' })

      # Run filter
      result = filter.run('<%= "I was hiding in #{yield}." %>')
      assert_equal('I was hiding in a cheap motel.', result)
    end
  end

  def test_filter_with_yield_without_content
    if_have 'erubis' do
      # Create filter
      filter = ::Nanoc::Filters::Erubis.new({ :location => 'a cheap motel' })

      # Run filter
      assert_raises LocalJumpError do
        filter.run('<%= "I was hiding in #{yield}." %>')
      end
    end
  end

  def test_filter_with_erbout
    if_have 'erubis' do
      filter = ::Nanoc::Filters::Erubis.new
      result = filter.run('stuff<% _erbout << _erbout %>')
      assert_equal 'stuffstuff', result
    end
  end

end
