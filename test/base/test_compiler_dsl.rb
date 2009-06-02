# encoding: utf-8

require 'test/helper'

class Nanoc3::CompilerDSLTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_compile
    # TODO implement
  end

  def test_map
    # TODO implement
  end

  def test_layout
    # TODO implement
  end

  def test_identifier_to_regex_without_wildcards
    # Create compiler DSL
    compiler_dsl = Nanoc3::CompilerDSL.new(nil)

    # Check
    assert_equal(
      /^foo$/,
      compiler_dsl.instance_eval { identifier_to_regex('foo') }
    )
  end

  def test_identifier_to_regex_with_one_wildcard
    # Create compiler DSL
    compiler_dsl = Nanoc3::CompilerDSL.new(nil)

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo/*/bar') }
    expected = %r{^foo/(.*?)/bar$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_two_wildcards
    # Create compiler DSL
    compiler_dsl = Nanoc3::CompilerDSL.new(nil)

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo/*/bar/*/qux') }
    expected = %r{^foo/(.*?)/bar/(.*?)/qux$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

end
