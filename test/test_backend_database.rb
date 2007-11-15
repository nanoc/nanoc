require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class DatabaseBackendTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
  end

  def teardown
    Dir['test/fixtures/*/output/*'].each { |f| FileUtils.remove_entry_secure f if File.exist?(f)}
    $quiet = false
  end

  def test_foo
  end

end
