# encoding: utf-8

class Nanoc::CLI::Commands::CreateSiteTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_create_site_with_existing_name
    Nanoc::CLI.run %w( create_site foo )
    assert_raises(::Nanoc::Errors::GenericTrivial) do
      Nanoc::CLI.run %w( create_site foo )
    end
  end

  def test_can_compile_new_site
    Nanoc::CLI.run %w( create_site foo )

    FileUtils.cd('foo') do
      site = Nanoc::Site.new('.')
      site.load_data
      site.compile
    end
  end

end
