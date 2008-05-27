require 'helper'

class Nanoc::AutoCompilerTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestWorkingPage

    def content(stage)
      "compiled page content (#{stage})"
    end

    def disk_path
      "tmp/test.html"
    end

  end

  class TestBrokenPage

    def content(stage)
      raise RuntimeError.new("aah! fail!")
    end

    def web_path
      "/foobar/"
    end

  end

  class TestCompiler

    def run(page, include_outdated)
      page.content(:post)
    end

  end

  class TestSite

    def compiler
      @compiler ||= TestCompiler.new
    end

  end

  class TestResponse

    attr_accessor :status, :body

    def initialize
      @attributes = {}
    end

    def [](key)
      @attributes[key]
    end

    def []=(key, value)
      @attributes[key] = value
    end

  end

  def test_start
    # TODO implement
  end

  def test_handle_request
    # TODO implement
  end

  def test_h
    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(self)

    # Check HTML escaping
    assert_equal(
      '&lt; &amp; &gt; \' &quot;',
      autocompiler.instance_eval { h('< & > \' "') }
    )
  end

  def test_serve_400
    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(self)

    # Create mock response
    response = TestResponse.new

    # Fill response for 404
    autocompiler.instance_eval do
      serve_404('/foo/bar/baz/', response)
    end

    # Check response
    assert_equal(404,                   response.status)
    assert_equal('text/html',           response['Content-Type'])
    assert_match(/404 File Not Found/,  response.body)
  end

  def test_serve_500
    # Create autocompiler
    autocompiler = Nanoc::AutoCompiler.new(nil)

    # Create mock response
    response = TestResponse.new

    # Fill response for 500
    autocompiler.instance_eval do
      begin
        raise RuntimeError.new("boink")
      rescue RuntimeError => e
        serve_500('/foo/bar/baz/', e, response)
      end
    end

    # Check response
    assert_equal(500,                     response.status)
    assert_equal('text/html',             response['Content-Type'])
    assert_match(/500 Server Error/,      response.body)
    assert_match(/Unknown error: boink/,  response.body)
  end

  def test_serve_page
    if_have('mime/types') do
      # Create site
      site = TestSite.new

      # Create autocompiler
      autocompiler = Nanoc::AutoCompiler.new(site)

      begin
        # Create working page
        working_page      = TestWorkingPage.new
        working_response  = TestResponse.new
        assert_nothing_raised do
          autocompiler.instance_eval { serve_page(working_page, working_response) }
        end

        # Create output file
        File.open(working_page.disk_path, 'w') { |io| }

        # Check response
        assert_equal(200,                     working_response.status)
        assert_equal('text/html',             working_response['Content-Type'])
        assert_match(/compiled page content/, working_response.body)
      ensure
        # Clean up
        FileUtils.remove_entry_secure(working_page.disk_path)
      end

      begin
        # Create broken page
        broken_page     = TestBrokenPage.new
        broken_response = TestResponse.new
        assert_nothing_raised do
          autocompiler.instance_eval { serve_page(broken_page, broken_response) }
        end

        # Check response
        assert_equal(500,                 broken_response.status)
        assert_equal('text/html',         broken_response['Content-Type'])
        assert_match(/aah! fail!/,        broken_response.body)
        assert_match(/500 Server Error/,  broken_response.body)
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

      # Create mock response
      response = TestResponse.new

      # Fill response for file 1
      autocompiler.instance_eval do
        serve_file('tmp/test.css', response)
      end

      # Check response
      assert_equal(200,         response.status)
      assert_equal('text/css',  response['Content-Type'])
      assert(response.body.include?('body { color: blue; }'))

      # Create mock response
      response = TestResponse.new

      # Fill response for file 2
      autocompiler.instance_eval do
        serve_file('tmp/test', response)
      end

      # Check response
      assert_equal(200,                         response.status)
      assert_equal('application/octet-stream',  response['Content-Type'])
      assert(response.body.include?('random blah blah stuff'))
    end
  end

end
