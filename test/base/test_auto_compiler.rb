require 'helper'

class Nanoc::AutoCompilerTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

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
    autocompiler = Nanoc::AutoCompiler.new(self)

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
    # TODO implement
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
