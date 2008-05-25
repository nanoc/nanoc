require 'helper'

class Nanoc::CLI::CreateSiteCommandTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_stub
  end

  # FIXME re-enable
  # def test_create_site
  #   in_dir %w{ tmp } do
  #     Nanoc::Site.create('site')
  #   end
  # 
  #   assert(File.directory?('tmp/site/'))
  # 
  #   assert(File.file?('tmp/site/config.yaml'))
  #   assert(File.file?('tmp/site/meta.yaml'))
  #   assert(File.file?('tmp/site/Rakefile'))
  # 
  #   assert(File.directory?('tmp/site/content/'))
  #   assert(File.file?('tmp/site/content/content.txt'))
  #   assert(File.file?('tmp/site/content/content.yaml'))
  # 
  #   assert(File.directory?('tmp/site/layouts/'))
  #   assert(File.directory?('tmp/site/layouts/default/'))
  #   assert(File.file?('tmp/site/layouts/default/default.erb'))
  #   assert(File.file?('tmp/site/layouts/default/default.yaml'))
  # 
  #   assert(File.directory?('tmp/site/lib/'))
  #   assert(File.file?('tmp/site/lib/default.rb'))
  # 
  #   assert(File.directory?('tmp/site/output/'))
  # 
  #   assert(File.directory?('tmp/site/templates/'))
  #   assert(File.directory?('tmp/site/templates/default/'))
  #   assert(File.file?('tmp/site/templates/default/default.txt'))
  #   assert(File.file?('tmp/site/templates/default/default.yaml'))
  # 
  #   assert(File.directory?('tmp/site/tasks/'))
  #   assert(File.file?('tmp/site/tasks/default.rake'))
  # end
  # 
  # def test_create_site_with_existing_name
  #   in_dir %w{ tmp } do
  #     assert_nothing_raised()   { Nanoc::Site.create('site') }
  #     assert_raise(SystemExit)  { Nanoc::Site.create('site') }
  #   end
  # end

end
