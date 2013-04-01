# encoding: utf-8

class Nanoc::Extra::Checking::Checks::ExternalLinksTest < Nanoc::TestCase

  def test_run
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/foo.txt',  'w') { |io| io.write('<a href="http://example.com/404">broken</a>') }
      File.open('output/bar.html', 'w') { |io| io.write('<a href="http://example.com/">not broken</a>') }

      # Create check
      check = Nanoc::Extra::Checking::Checks::ExternalLinks.new(site)
      def check.request_url_once(url)
        Net::HTTPResponse.new('1.1', url.path == '/' ? '200' : '404', 'okay')
      end
      check.run

      # Test
      assert check.issues.empty?
    end
  end

  def test_valid_by_path
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

  def test_valid_by_query
    with_site do |site|
      # Create check
      check = Nanoc::Extra::Checking::Checks::ExternalLinks.new(site)
      def check.request_url_once(url)
        Net::HTTPResponse.new('1.1', url.query == 'status=200' ? '200' : '404', 'okay')
      end

      # Test
      assert_nil check.validate('http://example.com/?status=200')
      refute_nil check.validate('http://example.com/?status=404')
    end
  end

  def test_fallback_to_get_when_head_is_not_allowed
    with_site do |site|
      #Create check
      check = Nanoc::Extra::Checking::Checks::ExternalLinks.new(site)
      def check.request_url_once(url, req_method = Net::HTTP::Head)
        Net::HTTPResponse.new('1.1', (req_method == Net::HTTP::Head || url.path == '/405') ? '405' : '200', 'okay')
      end

      #Test
      assert_nil check.validate('http://127.0.0.1:9204')
      refute_nil check.validate('http://127.0.0.1:9204/405')
    end
  end

  def test_path_for_url
    with_site do |site|
      check = Nanoc::Extra::Checking::Checks::ExternalLinks.new(site)

      assert_equal '/',             check.send(:path_for_url, URI.parse('http://example.com'))
      assert_equal '/',             check.send(:path_for_url, URI.parse('http://example.com/'))
      assert_equal '/?foo=bar',     check.send(:path_for_url, URI.parse('http://example.com?foo=bar'))
      assert_equal '/?foo=bar',     check.send(:path_for_url, URI.parse('http://example.com/?foo=bar'))
      assert_equal '/meow?foo=bar', check.send(:path_for_url, URI.parse('http://example.com/meow?foo=bar'))
    end
  end

end
