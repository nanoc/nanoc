# encoding: utf-8

class Nanoc::SiteTest < Nanoc::TestCase

  def test_initialize_with_dir_without_config_yaml
    assert_raises(Nanoc::Errors::GenericTrivial) do
      Nanoc::SiteLoader.new.load
    end
  end

  def test_initialize_with_dir_with_config_yaml
    File.write('config.yaml', 'output_dir: public_html')
    site = Nanoc::SiteLoader.new.load
    assert_equal 'public_html', site.config[:output_dir]
  end

  def test_initialize_with_dir_with_nanoc_yaml
    File.write('nanoc.yaml', 'output_dir: public_html')
    site = Nanoc::SiteLoader.new.load
    assert_equal 'public_html', site.config[:output_dir]
  end

  def test_load_data_sources_first
    # Create site
    Nanoc::CLI.run %w( create_site bar)

    FileUtils.cd('bar') do
      # Create data source code
      File.open('lib/some_data_source.rb', 'w') do |io|
        io.write "class FooDataSource < Nanoc::DataSource\n"
        io.write "  identifier :site_test_foo\n"
        io.write "  def items ; [ Nanoc::Item.new('content', {}, '/foo/') ] ; end\n"
        io.write "end\n"
      end

      # Update configuration
      File.open('nanoc.yaml', 'w') do |io|
        io.write "data_sources:\n"
        io.write "  - type: site_test_foo"
      end

      # Create site
      site = Nanoc::SiteLoader.new.load

      # Check
      assert_equal 1,      site.data_sources.size
      assert_equal '/foo', site.items[0].identifier.to_s
    end
  end

end

describe 'Nanoc::Site#data_sources' do

  include Nanoc::TestHelpers

  it 'should raise for unknown data sources' do
    proc do
      in_site do
        File.open('nanoc.yaml', 'w') do |io|
          io.write "data_sources:\n"
          io.write "  -\n"
          io.write "    type: sdjhkgfdsdfghj\n"
        end
        Nanoc::SiteLoader.new.load
      end
    end.must_raise Nanoc::Errors::UnknownDataSource
  end

  it 'should also use the toplevel config for data sources' do
    in_site do
      File.open('nanoc.yaml', 'w') do |io|
        io.write "data_sources:\n"
        io.write "  -\n"
        io.write "    type: filesystem\n"
        io.write "    aaa: one\n"
        io.write "    config:\n"
        io.write "      bbb: two\n"
      end

      site = Nanoc::SiteLoader.new.load
      data_sources = site.data_sources

      assert data_sources.first.config[:aaa] = 'one'
      assert data_sources.first.config[:bbb] = 'two'
    end
  end

end
