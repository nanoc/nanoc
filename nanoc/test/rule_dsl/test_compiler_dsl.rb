# frozen_string_literal: true

require 'helper'

class Nanoc::RuleDSL::CompilerDSLTest < Nanoc::TestCase
  def test_compile
    # TODO: implement
  end

  def test_route
    # TODO: implement
  end

  def test_layout
    # TODO: implement
  end

  def test_preprocess_twice
    rules_collection = Nanoc::RuleDSL::RulesCollection.new
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(rules_collection, {})

    # first time
    io = capturing_stdio do
      compiler_dsl.preprocess {}
    end

    assert_empty io[:stdout]
    assert_empty io[:stderr]

    # second time
    io = capturing_stdio do
      compiler_dsl.preprocess {}
    end

    assert_empty io[:stdout]
    assert_match(/WARNING: A preprocess block is already defined./, io[:stderr])
  end

  def test_postprocess_twice
    rules_collection = Nanoc::RuleDSL::RulesCollection.new
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(rules_collection, {})

    # first time
    io = capturing_stdio do
      compiler_dsl.postprocess {}
    end

    assert_empty io[:stdout]
    assert_empty io[:stderr]

    # second time
    io = capturing_stdio do
      compiler_dsl.postprocess {}
    end

    assert_empty io[:stdout]
    assert_match(/WARNING: A postprocess block is already defined./, io[:stderr])
  end

  def test_postprocessor_modified_method
    with_site do |_site|
      # Create rules
      File.write('Rules', <<~EOS)
        compile '*' do
        end
        route '*' do
        end
        postprocess do
          puts @items.select(&:modified).length
        end
      EOS

      File.write('content/index.html', 'o hello')

      io = capturing_stdio do
        site = Nanoc::Core::SiteLoader.new.new_from_cwd
        Nanoc::Core::Compiler.compile(site)
      end

      assert_match(/1/, io[:stdout])
    end
  end

  def test_include_rules
    with_site(legacy: false) do |_site|
      # Create a bonus rules file
      File.write(
        'more_rules.rb',
        "passthrough '/index.*'",
      )

      # Adjust normal rules file
      File.write(
        'Rules',
        "include_rules 'more_rules'\n\n" \
          "route '/**/*' do ; nil ; end\n\n" \
          "compile '/**/*' do ; end\n",
      )

      # Create items
      File.write('content/index.html', 'hello!')

      # Compile
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      # Check
      assert File.file?('output/index.html')
    end
  end

  def test_passthrough
    with_site do
      # Create rules
      File.write('Rules', <<~EOS)
        passthrough "/robots/"

        compile '*' do ; end
        route '*' do ; item.identifier.chop + '-xyz' + item[:extension] ; end
      EOS

      # Create items
      assert_predicate Dir['content/*'], :empty?
      File.write('content/robots.txt', 'Hello I am robots')

      # Compile
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      # Check paths
      assert_equal ['output/robots.txt'], Dir['output/*']
    end
  end

  def test_passthrough_no_ext
    with_site do
      # Create rules
      File.write('Rules', <<~EOS)
        passthrough "/foo/"
      EOS

      # Create items
      assert_predicate Dir['content/*'], :empty?
      File.write('content/foo', 'Hello I am foo')

      # Compile
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      # Check paths
      assert_equal ['output/foo'], Dir['output/*']
    end
  end

  def test_passthrough_priority
    with_site do
      # Create rules
      File.write('Rules', <<~EOS)
        compile '*' do
          filter :erb
        end

        route '*' do
          item.identifier + 'index.html'
        end

        passthrough "/foo/"
      EOS

      # Create items
      assert_predicate Dir['content/*'], :empty?
      File.write('content/foo.txt', "Hello I am <%= 'foo' %>")

      # Compile
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      # Check paths
      assert_equal ['output/foo'],            Dir['output/*']
      assert_equal ['output/foo/index.html'], Dir['output/foo/*']
    end
  end

  def test_passthrough_with_full_identifiers
    with_site do
      File.open('nanoc.yaml', 'w') do |io|
        io << 'string_pattern_type: legacy' << "\n"
        io << 'data_sources:' << "\n"
        io << '  -' << "\n"
        io << '    type: filesystem' << "\n"
        io << '    identifier_type: full' << "\n"
      end

      # Create rules
      File.open('Rules', 'w') do |io|
        io << 'passthrough \'*\''
      end

      # Create items
      assert_predicate Dir['content/*'], :empty?
      File.write('content/robots.txt', 'Hello I am robots')

      # Compile
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      # Check paths
      assert_equal ['output/robots.txt'], Dir['output/*']
    end
  end

  def test_ignore
    with_site do
      # Create rules
      File.write('Rules', <<~EOS)
        ignore '/lame/'

        passthrough '*'
      EOS

      # Create items
      assert_predicate Dir['content/*'], :empty?
      File.write('content/lame.txt', 'Hello I am lame')

      File.write('content/notlame.txt', 'Hello I am not lame')

      # Compile
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      # Check paths
      assert_equal ['output/notlame.txt'], Dir['output/*']
    end
  end

  def test_ignore_priority
    with_site do
      # Create rules
      File.write('Rules', <<~EOS)
        compile '*' do
          filter :erb
        end

        route '*' do
          item.identifier + 'index.html'
        end

        ignore "/foo/"
      EOS

      # Create items
      assert_predicate Dir['content/*'], :empty?
      File.write('content/foo.txt', "Hello I am <%= 'foo' %>")

      # Compile
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      # Check paths
      assert_equal ['output/foo'],            Dir['output/*']
      assert_equal ['output/foo/index.html'], Dir['output/foo/*']
    end
  end

  def test_create_pattern_with_string_with_no_config
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, {})

    err = assert_raises(Nanoc::Core::TrivialError) do
      compiler_dsl.create_pattern('/foo/*')
    end

    assert_equal 'Invalid string_pattern_type: ', err.message
  end

  def test_create_pattern_with_string_with_glob_string_pattern_type
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, string_pattern_type: 'glob')

    pattern = compiler_dsl.create_pattern('/foo/*')

    # rubocop:disable Minitest/AssertMatch
    # rubocop:disable Minitest/RefuteMatch
    assert pattern.match?('/foo/aaaa')
    refute pattern.match?('/foo/aaaa/')
    refute pattern.match?('/foo/a/a/a/a')
    # rubocop:enable Minitest/RefuteMatch
    # rubocop:enable Minitest/AssertMatch Minitest/RefuteMatch
  end

  def test_create_pattern_with_regex
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, string_pattern_type: 'glob')

    pattern = compiler_dsl.create_pattern(%r{\A/foo/a*/})

    # rubocop:disable Minitest/AssertMatch
    assert pattern.match?('/foo/aaaa/')
    # rubocop:enable Minitest/AssertMatch
  end

  def test_create_pattern_with_string_with_unknown_string_pattern_type
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, string_pattern_type: 'donkey')

    err = assert_raises(Nanoc::Core::TrivialError) do
      compiler_dsl.create_pattern('/foo/*')
    end

    assert_equal 'Invalid string_pattern_type: donkey', err.message
  end

  def test_identifier_to_regex_without_wildcards
    # Create compiler DSL
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo') }
    expected = %r{^/foo/?$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_one_wildcard
    # Create compiler DSL
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo/*/bar') }
    expected = %r{^/foo/(.*?)/bar/?$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_two_wildcards
    # Create compiler DSL
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo/*/bar/*/qux') }
    expected = %r{^/foo/(.*?)/bar/(.*?)/qux/?$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_just_one_wildcard
    # Create compiler DSL
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('*') }
    expected = %r{^/(.*?)$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_root
    # Create compiler DSL
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('/') }
    expected = %r{^/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_only_children
    # Create compiler DSL
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('/foo/*/') }
    expected = %r{^/foo/(.*?)/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_plus_wildcard
    # Create compiler DSL
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('/foo/+') }
    expected = %r{^/foo/(.+?)/?$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)

    # rubocop:disable Minitest/AssertMatch
    # rubocop:disable Minitest/RefuteMatch
    assert('/foo/bar/' =~ actual)
    refute('/foo/' =~ actual)
    # rubocop:enable Minitest/RefuteMatch
    # rubocop:enable Minitest/AssertMatch
  end

  def test_identifier_to_regex_with_full_identifier
    # Create compiler DSL
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('/favicon.ico') }
    expected = %r{^/favicon\.ico/?$}

    assert_equal(expected.to_s, actual.to_s)

    # rubocop:disable Minitest/AssertMatch
    # rubocop:disable Minitest/RefuteMatch
    assert('/favicon.ico' =~ actual)
    assert('/favicon.ico/' =~ actual)
    refute('/faviconxico' =~ actual)
    # rubocop:enable Minitest/RefuteMatch
    # rubocop:enable Minitest/AssertMatch
  end

  def test_dsl_has_no_access_to_compiler
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, {})
    assert_raises(NameError) do
      compiler_dsl.instance_eval { compiler }
    end
  end

  def test_config
    $venetian = 'unsnares'
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, venetian: 'snares')
    compiler_dsl.instance_eval { $venetian = @config[:venetian] }

    assert_equal 'snares', $venetian
  end

  def test_config_without_sigil
    $venetian = 'unsnares'
    compiler_dsl = Nanoc::RuleDSL::CompilerDSL.new(nil, venetian: 'snares')
    compiler_dsl.instance_eval { $venetian = config[:venetian] }

    assert_equal 'snares', $venetian
  end
end
