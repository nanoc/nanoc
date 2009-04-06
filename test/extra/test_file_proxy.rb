require 'test/helper'

class Nanoc3::Extra::FileProxyTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_stub
    # Create test file
    File.open('tmp/test.txt', 'w') { |io| }

    # Create lots of file proxies
    count = Process.getrlimit(Process::RLIMIT_NOFILE)[0] + 5
    file_proxies = []
    count.times { file_proxies << Nanoc3::Extra::FileProxy.new('tmp/test.txt') }
  end

end
