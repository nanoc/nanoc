class Nanoc::CLI::Commands::SyncTest < Nanoc::TestCase

  def test_run
    with_site do
      File.open('lib/foo_data_source.rb', 'w') do |io|
        io.write "class FooDataSource < Nanoc::DataSource\n"
        io.write "  identifier :sync_test_foo\n"
        io.write "  def sync\n"
        io.write "    File.open('foo_source_data.yaml', 'w') do |io|\n"
        io.write "      io.write 'sync: true'\n"
        io.write "    end\n"
        io.write "  end\n"
        io.write "end\n"
      end

      File.open('nanoc.yaml', 'w') do |io|
        io.write "data_sources:\n"
        io.write "  - type: sync_test_foo\n"
        io.write "    items_root: /"
      end

      Nanoc::CLI.run %w( sync )

      assert File.file?('foo_source_data.yaml')
      assert_equal File.read('foo_source_data.yaml'), 'sync: true'
    end
  end

end
