# encoding: utf-8

class Nanoc::CompilerDSLTest < Nanoc::TestCase

  def setup
    super
    @rules_collection = Nanoc::RulesCollection.new
    @compiler_dsl = Nanoc::CompilerDSL.new(@rules_collection)
  end

  def test_compile
    # TODO implement
  end

  def test_route
    # TODO implement
  end

  def test_layout
    # TODO implement
  end

  def new_snapshot_store
    Nanoc::SnapshotStore::InMemory.new
  end

  def test_include_rules
    with_site do
      # Create rep
      item = Nanoc::Item.new('foo', { :extension => 'bar' }, '/foo.bar')
      rep  = Nanoc::ItemRep.new(item, :default, :snapshot_store => self.new_snapshot_store)

      # Create a bonus rules file
      File.write('more_rules.rb', "passthrough '/foo.*'")

      # Create other necessary stuff
      site = Nanoc::Site.new('.')
      site.items << item
      dsl = Nanoc::CompilerDSL.new(site.compiler.rules_collection)

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
passthrough '/robots.*'

compile '*' do
end

route '*' do
  item.identifier.without_ext + '-xyz.' + item.identifier.extension
end
EOS
      end

      # Create items
      assert Dir['content/*'].empty?
      File.write('content/robots.txt', 'Hello I am robots')

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
passthrough '/foo'
EOS
      end

      # Create items
      assert Dir['content/*'].empty?
      File.write('content/foo', 'Hello I am foo')

      # Compile
      site = Nanoc::Site.new('.')
      site.compile

      # Check paths
      assert_equal [ 'output/foo' ], Dir['output/*']
    end
  end

  def test_passthrough_with_ext_from_static_data_source
    with_site do
      # Create config
      File.open('nanoc.yaml', 'w') do |io|
        io.write "data_sources:\n"
        io.write "  - type: static\n"
      end

      # Create rules
      File.open('Rules', 'w') do |io|
        io.write <<EOS
passthrough "/foo.txt"
EOS
      end

      # Create items
      FileUtils.mkdir_p('static')
      File.open('static/foo.txt', 'w') do |io|
        io.write "Hello I am foo"
      end

      # Compile
      site = Nanoc::Site.new('.')
      site.compile

      # Check paths
      assert_equal [ 'output/foo.txt' ], Dir['output/*']
    end
  end

  def test_passthrough_priority
    with_site do
      # Create rules
      File.write('Rules', <<EOS)
compile '*' do
  filter :erb
end

route '*' do
  item.identifier.without_ext + '/index.html'
end

passthrough "/foo.*"
EOS

      # Create items
      assert Dir['content/*'].empty?
      File.write('content/foo.txt', "Hello I am <%= 'foo' %>")

      # Compile
      site = Nanoc::Site.new('.')
      site.compile

      # Check paths
      assert_equal [ 'output/foo/index.html' ], Dir['output/**/*'].select { |fn| File.file?(fn) }
      assert_equal "Hello I am foo", File.read('output/foo/index.html')
    end
  end

  def test_ignore
    with_site do
      # Create rules
      File.open('Rules', 'w') do |io|
        io.write <<EOS
ignore '/lame.*'

passthrough '*'
EOS
      end

      # Create items
      assert Dir['content/*'].empty?
      File.open('content/lame.txt', 'w') do |io|
        io.write "Hello I am lame"
      end

      File.open('content/notlame.txt', 'w') do |io|
        io.write "Hello I am not lame"
      end

      # Compile
      site = Nanoc::Site.new('.')
      site.compile

      # Check paths
      assert_equal [ 'output/notlame.txt'], Dir['output/*']
    end
  end

  def test_ignore_priority
    with_site do
      # Create rules
      File.open('Rules', 'w') do |io|
        io.write <<EOS
compile '*' do
  filter :erb
end

route '*' do
  item.identifier.without_ext + '/index.html'
end

ignore 'foo.*'
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
    compiler_dsl = Nanoc::CompilerDSL.new(nil)

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo') }
    expected = %r{^/foo$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_one_wildcard
    actual   = @compiler_dsl.instance_eval { identifier_to_regex('foo/*/bar') }
    expected = %r{^/foo/(.*?)/bar$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_two_wildcards
    actual   = @compiler_dsl.instance_eval { identifier_to_regex('foo/*/bar/*/qux') }
    expected = %r{^/foo/(.*?)/bar/(.*?)/qux$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_just_one_wildcard
    actual   = @compiler_dsl.instance_eval { identifier_to_regex('*') }
    expected = %r{^/(.*?)$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_root
    actual   = @compiler_dsl.instance_eval { identifier_to_regex('/') }
    expected = %r{^/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_only_children
    actual   = @compiler_dsl.instance_eval { identifier_to_regex('/foo/*/') }
    expected = %r{^/foo/(.*?)/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_plus_wildcard
    actual   = @compiler_dsl.instance_eval { identifier_to_regex('/foo/+') }
    expected = %r{^/foo/(.+?)$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
    assert('/foo/bar/' =~ actual)
    assert('/foo/bar'  =~ actual)
    refute('/foo/'     =~ actual)
    refute('/foo'      =~ actual)
  end

  def test_dsl_has_no_access_to_compiler
    assert_raises(NameError) do
      @compiler_dsl.instance_eval { compiler }
    end
  end

end
