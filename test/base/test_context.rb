# encoding: utf-8

class Nanoc3::ContextTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_context_with_instance_variable
    # Create context
    context = Nanoc3::Context.new({ :foo => 'bar', :baz => 'quux' })

    # Ensure correct evaluation
    assert_equal('bar', eval("@foo", context.get_binding))
  end

  def test_context_with_instance_method
    # Create context
    context = Nanoc3::Context.new({ :foo => 'bar', :baz => 'quux' })

    # Ensure correct evaluation
    assert_equal('bar', eval("foo", context.get_binding))
  end

  def test_example
    # Parse
    YARD.parse('../lib/nanoc3/base/context.rb')

    # Run
    assert_examples_correct 'Nanoc3::Context#initialize'
  end

end
