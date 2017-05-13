# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::PandocTest < Nanoc::TestCase
  def test_filter
    if_have 'pandoc-ruby' do
      skip_unless_have_command 'pandoc'

      # Create filter
      filter = ::Nanoc::Filters::Pandoc.new

      # Run filter
      result = filter.setup_and_run("# Heading\n")
      assert_match(%r{<h1 id=\"heading\">Heading</h1>\s*}, result)
    end
  end

  def test_params_old
    if_have 'pandoc-ruby' do
      skip_unless_have_command 'pandoc'

      # Create filter
      filter = ::Nanoc::Filters::Pandoc.new

      # Run filter
      args = { f: :markdown, to: :html }
      result = filter.setup_and_run("# Heading\n", args)
      assert_match(%r{<h1 id=\"heading\">Heading</h1>\s*}, result)
    end
  end

  def test_params_new
    if_have 'pandoc-ruby' do
      skip_unless_have_command 'pandoc'

      # Create filter
      filter = ::Nanoc::Filters::Pandoc.new

      # Run filter
      args = [:s, { f: :markdown, to: :html }, 'no-wrap', :toc]
      result = filter.setup_and_run("# Heading\n", args: args)
      assert_match '<div id="TOC">', result
      assert_match(%r{<h1 id=\"heading\">Heading</h1>\s*}, result)
    end
  end
end
