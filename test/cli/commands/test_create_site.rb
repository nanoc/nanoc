require 'test/helper'

class Nanoc::CLI::CreateSiteCommandTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_create_site_with_existing_name
    in_dir %w{ tmp } do
      Nanoc::CLI::Base.new.run([ 'create_site', 'foo' ])
      assert_raises(SystemExit)  { Nanoc::CLI::Base.new.run([ 'create_site', 'foo' ]) }
    end
  end

end
