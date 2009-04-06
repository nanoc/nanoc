require 'test/helper'

class Nanoc3::Extra::ContextTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_context
    # Create context
    context = Nanoc3::Extra::Context.new({ :foo => 'bar', :baz => 'quux' })

    # Ensure correct evaluation
    assert_equal('bar', eval("@foo", context.get_binding))
  end

end
