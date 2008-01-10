require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class DataSourceDatabaseTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def creating_site
    in_dir %w{ tmp } do
      Nanoc::Site.create('site')
      in_dir %w{ site } do
        # Update configuration
        File.open('config.yaml', 'w') do |io|
          io.write(
            'output_dir:   "output"' + "\n" +
            'data_source:  "database"' + "\n" +
            'database:' + "\n" +
            '  adapter:    "sqlite3"' + "\n" +
            '  dbfile:     "content.sqlite3db"'
          )
        end

        # Get site
        site = Nanoc::Site.from_cwd
        site.setup
        site.load_data

        site.data_source.loading { yield site }
      end
    end
  end

  # Test preparation

  # DataSource#up and DataSource#down aren't tested here,
  # because they are implicitly tested in the other testing
  # methods, meaning that if #up or #down didn't work, the
  # other methods would fail as well. The #setup test
  # doesn't check the database schema for the same reason.

  def test_setup
    if_have 'active_record' do
      creating_site do |site|
        # Check whether database has been recreated
        assert(File.file?('content.sqlite3db'))
      end
    end
  end

  # Test loading data

  def test_pages
    if_have 'active_record' do
      creating_site do |site|
        assert_equal(1, Nanoc::DataSources::Database::DatabasePage.count)
        assert_equal(
          "# Built-in\n" +
          "\n" +
          "# Custom\n" +
          "title: \"A New Root Page\"\n",
          Nanoc::DataSources::Database::DatabasePage.find(:first).attributes['meta']
        )
      end
    end
  end

  def test_page_defaults
    if_have 'active_record' do
      creating_site do |site|
        assert_equal(1, Nanoc::DataSources::Database::DatabasePageDefault.count)
        assert_equal(
          "# Built-in\n" +
          "custom_path:  none\n" +
          "extension:    \"html\"\n" +
          "filename:     \"index\"\n" +
          "filters_post: []\n" +
          "filters_pre:  []\n" +
          "is_draft:     false\n" +
          "layout:       \"default\"\n" +
          "skip_output:  false\n" +
          "\n" +
          "# Custom\n",
          Nanoc::DataSources::Database::DatabasePageDefault.find(:first).attributes['meta']
        )
      end
    end
  end

  def test_templates
    if_have 'active_record' do
      creating_site do |site|
        assert_equal(1, Nanoc::DataSources::Database::DatabaseTemplate.count)
        assert_equal(
          "# Built-in\n" +
          "\n" +
          "# Custom\n" +
          "title: \"A New Page\"\n",
          Nanoc::DataSources::Database::DatabaseTemplate.find(:first).attributes['meta']
        )
      end
    end
  end

  def test_layouts
    if_have 'active_record' do
      creating_site do |site|
        assert_equal(1, Nanoc::DataSources::Database::DatabaseLayout.count)
        assert_equal(
          "<html>\n" +
          "  <head>\n" +
          "    <title><%= @page.title %></title>\n" +
          "  </head>\n" +
          "  <body>\n" +
          "<%= @page.content %>\n" +
          "  </body>\n" +
          "</html>",
          Nanoc::DataSources::Database::DatabaseLayout.find(:first).attributes['content']
        )
      end
    end
  end

  def test_code
    if_have 'active_record' do
      creating_site do |site|
        assert_equal(1, Nanoc::DataSources::Database::DatabaseCodePiece.count)
        assert_equal(
          "def html_escape(str)\n" +
          "  str.gsub('&', '&amp;').str('<', '&lt;').str('>', '&gt;').str('\"', '&quot;')\n" +
          "end\n" +
          "alias h html_escape\n",
          Nanoc::DataSources::Database::DatabaseCodePiece.find(:first).attributes['code']
        )
      end
    end
  end

  # Test creating data

  def test_create_page
    if_have 'active_record' do
      creating_site do |site|
        site.create_page('foo')

        assert_equal(2, Nanoc::DataSources::Database::DatabasePage.count)
        assert_equal(
          "# Built-in\n" +
          "\n" +
          "# Custom\n" +
          "title: A New Page\n",
          Nanoc::DataSources::Database::DatabasePage.find(:all).last.attributes['meta']
        )
      end
    end
  end

  def test_create_template
    if_have 'active_record' do
      creating_site do |site|
        site.create_template('bar')

        assert_equal(2, Nanoc::DataSources::Database::DatabaseTemplate.count)
        assert_equal(
          "# Built-in\n" +
          "\n" +
          "# Custom\n" +
          "title: A New Page\n",
          Nanoc::DataSources::Database::DatabaseTemplate.find(:all).last.attributes['meta']
        )
      end
    end
  end

  def test_create_layout
    if_have 'active_record' do
      creating_site do |site|
        site.create_layout('baz')

        assert_equal(2, Nanoc::DataSources::Database::DatabaseLayout.count)
        assert_equal(
          "<html>\n" +
          "  <head>\n" +
          "    <title><%= @page.title %></title>\n" +
          "  </head>\n" +
          "  <body>\n" +
          "<%= @page.content %>\n" +
          "  </body>\n" +
          "</html>",
          Nanoc::DataSources::Database::DatabaseLayout.find(:all).last.attributes['content']
        )
      end
    end
  end

end
