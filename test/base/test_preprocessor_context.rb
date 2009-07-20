# encoding: utf-8

require 'test/helper'

class Nanoc3::PreprocessorContextTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_objects
    # Mock everything
    config = mock
    items = mock
    layouts = mock
    site = mock
    site.stubs(:config).returns(config)
    site.stubs(:items).returns(items)
    site.stubs(:layouts).returns(layouts)

    # Create context
    @preprocessor_context = Nanoc3::PreprocessorContext.new(site)

    # Check
    assert_equal site,    @preprocessor_context.site
    assert_equal config,  @preprocessor_context.config
    assert_equal layouts, @preprocessor_context.layouts
    assert_equal items,   @preprocessor_context.items
  end

end
