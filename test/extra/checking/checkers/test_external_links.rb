# encoding: utf-8

class Nanoc::Extra::Checking::Checkers::ExternalLinksTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_valid?
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      FileUtils.mkdir_p('output/stuff')
      File.open('output/origin',     'w') { |io| io.write('hi') }
      File.open('output/foo',        'w') { |io| io.write('hi') }
      File.open('output/stuff/blah', 'w') { |io| io.write('hi') }

      # Create checker
      checker = Nanoc::Extra::Checking::Checkers::ExternalLinks.new(site)

      # Test
      self.run_server_while do
        assert ok?(checker, 'http://127.0.0.1:9204/200')
        assert ok?(checker, 'foo://example.com/')
        refute ok?(checker, 'http://127.0.0.1:9204">')
      end
    end
  end

  def ok?(checker, url)
    checker.validate(url).nil?
  end

  def run_server_while
    @app = lambda { |env| [ env['REQUEST_PATH'][1..-1].to_i, {}, [ '... Useless body ...' ] ] }
    @server = nil

    @thread = Thread.new do
      Rack::Handler::WEBrick.run(@app, :Host => @host='127.0.0.1', :Port => @port=9204) do |server|
        @server = server
      end
    end

    Thread.pass until @server

    yield

    @server.stop
    @thread.kill
  end

end
