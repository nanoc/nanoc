# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::ErubiTest < Nanoc::TestCase
  def test_filter_with_instance_variable
    # Create filter
    filter = ::Nanoc::Filters::Erubi.new(location: 'a cheap motel')

    # Run filter
    result = filter.setup_and_run('<%= "I was hiding in #{@location}." %>')

    assert_equal('I was hiding in a cheap motel.', result)
  end

  def test_filter_with_instance_method
    # Create filter
    filter = ::Nanoc::Filters::Erubi.new(location: 'a cheap motel')

    # Run filter
    result = filter.setup_and_run('<%= "I was hiding in #{location}." %>')

    assert_equal('I was hiding in a cheap motel.', result)
  end

  def test_filter_syntax_error
    # Create filter
    item = Nanoc::Core::Item.new('asdf', {}, '/about.md')
    item_rep = Nanoc::Core::ItemRep.new(item, :xml)
    filter = ::Nanoc::Filters::Erubi.new(item:, item_rep:)

    # Run filter
    raised = false
    begin
      filter.setup_and_run('<%= this isn\'t really ruby so it\'ll break, muahaha %>')
    rescue SyntaxError => e
      assert_match 'syntax error', e.message
      raised = true
    end

    assert raised
  end

  def test_filter_regular_error
    # Create filter
    item = Nanoc::Core::Item.new('asdf', {}, '/about.md')
    item_rep = Nanoc::Core::ItemRep.new(item, :xml)
    filter = ::Nanoc::Filters::Erubi.new(item:, item_rep:)

    # Run filter
    raised = false
    begin
      filter.setup_and_run('<%= undefined_method_2ff04e22 %>')
    rescue => e
      assert_match 'item /about.md (rep xml):1', e.backtrace.join("\n")
      raised = true
    end

    assert raised
  end

  def test_filter_with_yield
    # Create filter
    filter = ::Nanoc::Filters::Erubi.new(content: 'a cheap motel')

    # Run filter
    result = filter.setup_and_run('<%= "I was hiding in #{yield}." %>')

    assert_equal('I was hiding in a cheap motel.', result)
  end

  def test_filter_with_yield_without_content
    # Create filter
    filter = ::Nanoc::Filters::Erubi.new(location: 'a cheap motel')

    # Run filter
    assert_raises LocalJumpError do
      filter.setup_and_run('<%= "I was hiding in #{yield}." %>')
    end
  end

  def test_filter_with_erbout
    filter = ::Nanoc::Filters::Erubi.new
    result = filter.setup_and_run('stuff<% _erbout << _erbout %>')

    assert_equal 'stuffstuff', result
  end
end
