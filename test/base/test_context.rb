# encoding: utf-8

class Nanoc::ContextTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_context_with_instance_variable
    # Create context
    context = Nanoc::Context.new({ :foo => 'bar', :baz => 'quux' })

    # Ensure correct evaluation
    assert_equal('bar', eval("@foo", context.get_binding))
  end

  def test_context_with_instance_method
    # Create context
    context = Nanoc::Context.new({ :foo => 'bar', :baz => 'quux' })

    # Ensure correct evaluation
    assert_equal('bar', eval("foo", context.get_binding))
  end

  def test_example
    # Parse
    YARD.parse('../lib/nanoc/base/context.rb')

    # Run
    assert_examples_correct 'Nanoc::Context#initialize'
  end

end
