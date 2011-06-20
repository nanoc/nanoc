# encoding: utf-8

class Nanoc3::CLI::Commands::CreateSiteTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_create_site_with_existing_name
    Nanoc3::CLI.run %w( create_site foo )
    assert_raises(SystemExit) do
      Nanoc3::CLI.run %w( create_site foo )
    end
  end

  def test_can_compile_new_site
    Nanoc3::CLI.run %w( create_site foo )

    FileUtils.cd('foo') do
      site = Nanoc3::Site.new('.')
      site.load_data
      site.compile
    end
  end

end
