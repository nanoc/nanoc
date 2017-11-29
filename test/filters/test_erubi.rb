# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::ErubiTest < Nanoc::TestCase
  def test_filter_with_instance_variable
    # Create filter
    filter = ::Nanoc::Filters::Erubi.new(location: 'a cheap motel')

    # Run filter
    result = filter.setup_and_run('<%= "I was hiding in #{@location}." %>') # rubocop:disable Lint/InterpolationCheck
    assert_equal('I was hiding in a cheap motel.', result)
  end

  def test_filter_with_instance_method
    # Create filter
    filter = ::Nanoc::Filters::Erubi.new(location: 'a cheap motel')

    # Run filter
    result = filter.setup_and_run('<%= "I was hiding in #{location}." %>') # rubocop:disable Lint/InterpolationCheck
    assert_equal('I was hiding in a cheap motel.', result)
  end

  def test_filter_error
    # Create filter
    filter = ::Nanoc::Filters::Erubi.new

    # Run filter
    raised = false
    begin
      filter.setup_and_run('<%= this isn\'t really ruby so it\'ll break during parsing %>')
    rescue SyntaxError => e
      assert_match 'syntax error', e.message
      raised = true
    end
    assert raised

    raised = false
    begin
      filter.setup_and_run('<%= "almost valid" # breaks during run %>')
    rescue SyntaxError => e
      assert_match 'syntax error', e.message
      raised = true
    end
    assert raised

  end

  def test_filter_with_yield
    # Create filter
    filter = ::Nanoc::Filters::Erubi.new(content: 'a cheap motel')

    # Run filter
    result = filter.setup_and_run('<%= "I was hiding in #{yield}." %>') # rubocop:disable Lint/InterpolationCheck
    assert_equal('I was hiding in a cheap motel.', result)
  end

  def test_filter_with_yield_without_content
    # Create filter
    filter = ::Nanoc::Filters::Erubi.new(location: 'a cheap motel')

    # Run filter
    assert_raises LocalJumpError do
      filter.setup_and_run('<%= "I was hiding in #{yield}." %>') # rubocop:disable Lint/InterpolationCheck
    end
  end

  def test_filter_with_erbout
    filter = ::Nanoc::Filters::Erubi.new
    result = filter.setup_and_run('stuff<% _erbout << _erbout %>')
    assert_equal 'stuffstuff', result
  end
end
