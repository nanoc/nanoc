# frozen_string_literal: true

require 'helper'

class Nanoc::Int::ContextTest < Nanoc::TestCase
  def test_context_with_instance_variable
    # Create context
    context = Nanoc::Int::Context.new(foo: 'bar', baz: 'quux')

    # Ensure correct evaluation
    assert_equal('bar', eval('@foo', context.get_binding))
  end

  def test_context_with_instance_method
    # Create context
    context = Nanoc::Int::Context.new(foo: 'bar', baz: 'quux')

    # Ensure correct evaluation
    assert_equal('bar', eval('foo', context.get_binding))
  end

  def test_example
    # Parse
    YARD.parse(LIB_DIR + '/nanoc/base/entities/context.rb')

    # Run
    assert_examples_correct 'Nanoc::Int::Context#initialize'
  end

  def test_include
    context = Nanoc::Int::Context.new({})
    eval('include Nanoc::Helpers::HTMLEscape', context.get_binding)
    assert_equal('&lt;&gt;', eval('h("<>")', context.get_binding))
  end
end
