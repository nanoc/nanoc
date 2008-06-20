require 'helper'

class Nanoc::AutoCompilerTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestPage

    attr_reader :reps

    def initialize(reps)
      @reps = reps
    end

    def compile
      @reps.each { |r| r.compile }
    end

  end

  class TestWorkingPageRep

    attr_accessor :page

    def content(stage)
      "compiled page content (#{stage})"
    end

    def disk_path
      "tmp/test.html"
    end

    def web_path
      "/test.html"
    end

  end

  class TestBrokenPageRep

    attr_accessor :page

    def content(stage)
      raise RuntimeError.new("aah! fail!")
    end

    def disk_path
      "tmp/foobar/index.htm"
    end

    def web_path
      "/foobar/"
    end

  end

  class TestCompiler

    attr_reader :stack

    def initialize
      @stack = []
    end

    def run(objects, include_outdated)
      objects.each { |o| o.reps.each { |r| r.content(:post) } }
    end

  end

  class TestSite

    def compiler
      @compiler ||= TestCompiler.new
    end

  end

  def test_start
    # TODO implement
  end

  def test_preferred_handler
    # TODO implement
  end

  def test_handler_named
    require 'rack'

    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(nil)

    # Check handler without requirements
    assert_equal(
      Rack::Handler::WEBrick,
      autocompiler.instance_eval { handler_named(:webrick) }
    )

    # Check handler with requirements
    assert_raises(NameError) do
      Rack::Handler::Thin
    end
    assert_nothing_raised do
      autocompiler.instance_eval { handler_named(:thin) }
      assert_equal(
        Rack::Handler::Thin,
        autocompiler.instance_eval { handler_named(:thin) }
      )
    end
  end

  def test_handle_request
    # TODO implement
  end

  def test_h
    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(nil)

    # Check HTML escaping
    assert_equal(
      '&lt; &amp; &gt; \' &quot;',
      autocompiler.instance_eval { h('< & > \' "') }
    )
  end

  def test_mime_type_of
    require 'mime/types'

    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(nil)

    # Create known test file
    File.open('tmp/foo.html', 'w') { |io| }
    assert_equal(
      'text/html',
      autocompiler.instance_eval { mime_type_of('tmp/foo.html', 'huh') }
    )

    # Create unknown test file
    File.open('tmp/foo', 'w') { |io| }
    assert_equal(
      'huh',
      autocompiler.instance_eval { mime_type_of('tmp/foo', 'huh') }
    )
  end

  def test_serve_400
    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(nil)

    # Fill response for 404
    response = autocompiler.instance_eval { serve_404('/foo/bar/baz/') }

    # Check response
    assert_equal(404,                   response[0])
    assert_equal('text/html',           response[1]['Content-Type'])
    assert_match(/404 File Not Found/,  response[2][0])
  end

  def test_serve_500
    # Create autocompiler
    site = TestSite.new
    autocompiler = Nanoc::AutoCompiler.new(site)

    # Fill response for 500
    response = autocompiler.instance_eval do
      begin
        raise RuntimeError.new("boink")
      rescue RuntimeError => e
        serve_500('/foo/bar/baz/', e)
      end
    end

    # Check response
    assert_equal(500,                     response[0])
    assert_equal('text/html',             response[1]['Content-Type'])
    assert_match(/500 Server Error/,      response[2][0])
    assert_match(/Unknown error: boink/,  response[2][0])
  end

  def test_serve_page_rep
    if_have('mime/types') do
      # Create autocompiler
      site = TestSite.new
      autocompiler = Nanoc::AutoCompiler.new(site)

      begin
        # Create working page
        working_page_rep      = TestWorkingPageRep.new
        working_page          = TestPage.new([working_page_rep])
        working_page_rep.page = working_page
        File.open(working_page_rep.disk_path, 'w') { |io| }

        assert_nothing_raised do
          # Serve
          response = autocompiler.instance_eval { serve_page_rep(working_page_rep) }

          # Check response
          assert_equal(200,                     response[0])
          assert_equal('text/html',             response[1]['Content-Type'])
          assert_match(/compiled page content/, response[2][0])
        end
      ensure
        # Clean up
        FileUtils.remove_entry_secure(working_page_rep.disk_path)
      end

      begin
        # Create broken page
        broken_page_rep       = TestBrokenPageRep.new
        broken_page           = TestPage.new([broken_page_rep])
        broken_page_rep.page  = broken_page

        assert_nothing_raised do
          # Serve
          response = autocompiler.instance_eval { serve_page_rep(broken_page_rep) }

          # Check response
          assert_equal(500,                 response[0])
          assert_equal('text/html',         response[1]['Content-Type'])
          assert_match(/aah! fail!/,        response[2][0])
          assert_match(/500 Server Error/,  response[2][0])
        end
      end
    end
  end

  def test_serve_file
    if_have('mime/types') do
      # Create test files
      File.open('tmp/test.css', 'w') { |io| io.write("body { color: blue; }")  }
      File.open('tmp/test',     'w') { |io| io.write("random blah blah stuff") }

      # Create autocompiler
      autocompiler = Nanoc::AutoCompiler.new(self)

      # Test file 1
      assert_nothing_raised do
        # Serve
        response = autocompiler.instance_eval { serve_file('tmp/test.css') }

        # Check response
        assert_equal(200,         response[0])
        assert_equal('text/css',  response[1]['Content-Type'])
        assert(response[2][0].include?('body { color: blue; }'))
      end

      # Test file 2
      assert_nothing_raised do
        # Serve
        response = autocompiler.instance_eval { serve_file('tmp/test') }

        # Check response
        assert_equal(200,                         response[0])
        assert_equal('application/octet-stream',  response[1]['Content-Type'])
        assert(response[2][0].include?('random blah blah stuff'))
      end
    end
  end

end
