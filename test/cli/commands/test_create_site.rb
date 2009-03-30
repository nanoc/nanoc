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

  def test_can_compile_new_site
    in_dir %w{ tmp } do
      Nanoc3::CLI::Base.new.run([ 'create_site', 'foo' ])
      
      in_dir %w{ foo } do
        site = Nanoc3::Site.new(YAML.load_file('config.yaml'))
        site.load_data
        site.compiler.run
      end
    end
  end

end
