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

  def test_default_encoding
    original_encoding = Encoding.default_external
    Encoding.default_external = 'ISO-8859-1' # ew!

    Nanoc::CLI.run %w( create_site foo )

    FileUtils.cd('foo') do

      # Try with encoding = default encoding = utf-8
      File.open('content/index.html', 'w') { |io| io.write("Hello <\xD6>!\n") }
      site = Nanoc::Site.new('.')
      exception = assert_raises(RuntimeError) do
        site.compile
      end
      assert_equal "Could not read content/index.html because the file is not valid UTF-8.", exception.message

      # Try with encoding = specific
      File.open('nanoc.yaml', 'w') { |io| io.write("meh: true\n") }
      site = Nanoc::Site.new('.')
      site.compile
    end
    FileUtils
  ensure
    Encoding.default_external = original_encoding
  end

end
