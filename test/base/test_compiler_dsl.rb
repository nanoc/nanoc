# encoding: utf-8

class Nanoc::CompilerDSLTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_compile
    # TODO implement
  end

  def test_route
    # TODO implement
  end

  def test_layout
    # TODO implement
  end

  def test_passthrough
    # Create site
    Nanoc::CLI.run %w( create_site bar)
    FileUtils.cd('bar') do
      # Create rep
      item = Nanoc::Item.new('foo', { :extension => 'bar' }, '/foo/')
      rep = Nanoc::ItemRep.new(item, :default)

      # Create other necessary stuff
      site = Nanoc::Site.new('.')
      site.items << item
      compiler = site.compiler
      dsl = site.compiler.rules_collection.dsl

      # Create rule
      dsl.passthrough '/foo/'

      # Route and compile
      rule = compiler.rules_collection.routing_rule_for(rep)
      path = rule.apply_to(rep, :compiler => compiler)
      compiler.send :compile_rep, rep

      # Check result
      assert_equal 'foo', rep.compiled_content
      assert_equal '/foo.bar', path
    end
  end

  def test_passthrough_no_ext
    # Create site
    Nanoc::CLI.run %w( create_site bar)
    FileUtils.cd('bar') do
      # Create rep
      item = Nanoc::Item.new('foo', { :extension => nil }, '/foo/')
      rep = Nanoc::ItemRep.new(item, :default)

      # Create other necessary stuff
      site = Nanoc::Site.new('.')
      site.items << item
      compiler = site.compiler
      dsl = site.compiler.rules_collection.dsl

      # Create rule
      dsl.passthrough '/foo/'

      # Route and compile
      rule = compiler.rules_collection.routing_rule_for(rep)
      path = rule.apply_to(rep, :compiler => compiler)
      compiler.send :compile_rep, rep

      # Check result
      assert_equal 'foo', rep.compiled_content
      assert_equal '/foo', path
    end
  end

  def test_identifier_to_regex_without_wildcards
    # Create compiler DSL
    compiler_dsl = Nanoc::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo') }
    expected = %r{^/foo/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_one_wildcard
    # Create compiler DSL
    compiler_dsl = Nanoc::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo/*/bar') }
    expected = %r{^/foo/(.*?)/bar/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_two_wildcards
    # Create compiler DSL
    compiler_dsl = Nanoc::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo/*/bar/*/qux') }
    expected = %r{^/foo/(.*?)/bar/(.*?)/qux/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_just_one_wildcard
    # Create compiler DSL
    compiler_dsl = Nanoc::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('*') }
    expected = %r{^/(.*?)$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_root
    # Create compiler DSL
    compiler_dsl = Nanoc::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('/') }
    expected = %r{^/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_only_children
    # Create compiler DSL
    compiler_dsl = Nanoc::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('/foo/*/') }
    expected = %r{^/foo/(.*?)/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_plus_wildcard
    # Create compiler DSL
    compiler_dsl = Nanoc::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('/foo/+') }
    expected = %r{^/foo/(.+?)/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
    assert('/foo/bar/' =~ actual)
    refute('/foo/'     =~ actual)
  end

  def test_dsl_has_no_access_to_compiler
    compiler_dsl = Nanoc::CompilerDSL.new(nil, {})
    assert_raises(NameError) do
      compiler_dsl.instance_eval { compiler }
    end
  end

  def test_config
    $venetian = 'unsnares'
    compiler_dsl = Nanoc::CompilerDSL.new(nil, { :venetian => 'snares' })
    compiler_dsl.instance_eval { $venetian = @config[:venetian] }
    assert_equal 'snares', $venetian
  end

end
