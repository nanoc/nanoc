require 'test/helper'

class Nanoc::Extra::FileProxyTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_stub
    # Create test file
    File.open('tmp/test.txt', 'w') { |io| }

    # Create lots of file proxies
    count = Process.getrlimit(Process::RLIMIT_NOFILE)[0] + 5
    file_proxies = []
    count.times { file_proxies << Nanoc::Extra::FileProxy.new('tmp/test.txt') }
  end

end
