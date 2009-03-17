require 'test/helper'

class Nanoc3::CLI::CreateSiteCommandTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_create_site_with_existing_name
    in_dir %w{ tmp } do
      Nanoc3::CLI::Base.new.run([ 'create_site', 'foo' ])
      assert_raises(SystemExit) { Nanoc3::CLI::Base.new.run([ 'create_site', 'foo' ]) }
    end
  end

end
