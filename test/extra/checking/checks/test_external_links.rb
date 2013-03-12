# encoding: utf-8

class Nanoc::Extra::Checking::Checks::ExternalLinksTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_run
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/foo.txt',  'w') { |io| io.write('<a href="http://example.com/404">broken</a>') }
      File.open('output/bar.html', 'w') { |io| io.write('<a href="http://example.com/">not broken</a>') }

      # Create check
      check = Nanoc::Extra::Checking::Checks::InternalLinks.new(site)
      def check.request_url_once(url)
        Net::HTTPResponse.new('1.1', url.path == '/' ? '200' : '404', 'okay')
      end
      check.run

      # Test
      assert check.issues.empty?
    end
  end

  def test_valid?
    with_site do |site|
      # Create check
      check = Nanoc::Extra::Checking::Checks::ExternalLinks.new(site)
      def check.request_url_once(url)
        Net::HTTPResponse.new('1.1', url.path == '/200' ? '200' : '404', 'okay')
      end

      # Test
      assert_nil check.validate('http://127.0.0.1:9204/200')
      assert_nil check.validate('foo://example.com/')
      refute_nil check.validate('http://127.0.0.1:9204">')
    end
  end

end
