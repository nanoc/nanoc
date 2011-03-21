# encoding: utf-8

require 'test/helper'

class Nanoc3::Extra::FileProxyTest < Nanoc3::TestCase

  def test_create_many
    if_implemented do
      # Create test file
      File.open('test.txt', 'w') { |io| }

      # Create lots of file proxies
      count = Process.getrlimit(Process::RLIMIT_NOFILE)[0] + 5
      file_proxies = []
      count.times { file_proxies << Nanoc3::Extra::FileProxy.new('test.txt') }
    end
  end

end
