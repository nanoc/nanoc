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

  def test_include_rules
    # Create site
    Nanoc::CLI.run %w( create_site with_bonus_rules )
    FileUtils.cd('with_bonus_rules') do
      # Create rep
      item = Nanoc::Item.new('foo', { :extension => 'bar' }, '/foo/')
      rep  = Nanoc::ItemRep.new(item, :default)

      # Create a bonus rules file
      File.open('more_rules.rb', 'w') { |io| io.write "passthrough '/foo/'" }

      # Create other necessary stuff
      site = Nanoc::Site.new('.')
      site.items << item
      dsl = site.compiler.rules_collection.dsl

      # Include rules
      dsl.include_rules 'more_rules'

      # Check that the rule made it into the collection
      refute_nil site.compiler.rules_collection.routing_rule_for(rep)
    end
  end

  def test_passthrough
    with_site do
      # Create rules
      File.open('Rules', 'w') do |io|
        io.write <<EOS
passthrough "/robots/"
        
compile '*' do ; end
route '*' do ; item.identifier.chop + '-xyz' + item[:extension] ; end
EOS
      end

      # Create items
      assert Dir['content/*'].empty?
      File.open('content/robots.txt', 'w') do |io|
        io.write "Hello I am robots"
      end

      # Compile
      site = Nanoc::Site.new('.')
      site.compile

      # Check paths
      assert_equal [ 'output/robots.txt' ], Dir['output/*']
    end
  end

  def test_passthrough_no_ext
    with_site do
      # Create rules
      File.open('Rules', 'w') do |io|
        io.write <<EOS
passthrough "/foo/"
EOS
      end

      # Create items
      assert Dir['content/*'].empty?
      File.open('content/foo', 'w') do |io|
        io.write "Hello I am foo"
      end

      # Compile
      site = Nanoc::Site.new('.')
      site.compile

      # Check paths
      assert_equal [ 'output/foo' ], Dir['output/*']
    end
  end

  def test_passthrough_priority
    with_site do
      # Create rules
      File.open('Rules', 'w') do |io|
        io.write <<EOS
compile '*' do
  filter :erb
end

route '*' do
  item.identifier + 'index.html'
end

passthrough "/foo/"
EOS
      end

      # Create items
      assert Dir['content/*'].empty?
      File.open('content/foo.txt', 'w') do |io|
        io.write "Hello I am <%= 'foo' %>"
      end

      # Compile
      site = Nanoc::Site.new('.')
      site.compile

      # Check paths
      assert_equal [ 'output/foo' ],            Dir['output/*']
      assert_equal [ 'output/foo/index.html' ], Dir['output/foo/*']
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
