require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class TrivialBackendTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
  end

  def teardown
    $quiet = false
  end

  def test_compile_site_with_trivial_backend
    with_site_fixture 'site_with_trivial_backend' do |site|
      assert_nothing_raised() { site.compile! }
      assert(File.file?('output/index.html'))
      assert(File.file?('output/about/index.html'))
      assert_equal(2, Dir["output/*"].size)
      assert_match(/<body>Hi!<\/body>/, File.read('output/index.html'))
      assert_match(/<body>Hello there.<\/body>/, File.read('output/about/index.html'))
    end
  end

end
