# encoding: utf-8

class Nanoc::Extra::FileProxyTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_create_many
    if_implemented do
      # Create test file
      File.open('test.txt', 'w') { |io| }

      # Create lots of file proxies
      count = Process.getrlimit(Process::RLIMIT_NOFILE)[0] + 5
      file_proxies = []
      count.times { file_proxies << Nanoc::Extra::FileProxy.new('test.txt') }
    end
  end

end
