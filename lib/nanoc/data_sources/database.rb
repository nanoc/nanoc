begin ; require 'active_record' ; rescue LoadError ; end

module Nanoc::DataSources
  module Database

    ########## Helper classes ##########

    begin

      class DatabasePage < ActiveRecord::Base
        set_table_name 'pages'
      end

      class DatabasePageDefault < ActiveRecord::Base
        set_table_name 'page_defaults'
      end

      class DatabaseTemplate < ActiveRecord::Base
        set_table_name 'templates'
      end

      class DatabaseLayout < ActiveRecord::Base
        set_table_name 'layouts'
      end

      class DatabaseCodePiece < ActiveRecord::Base
        set_table_name 'code_pieces'
      end

    rescue NameError
    end

    class DatabaseDataSource < Nanoc::DataSource

      ########## Attributes ##########

      identifier  :database

      ########## Preparation ##########

      def up
        nanoc_require 'active_record'

        # Connect to the database
        ActiveRecord::Base.establish_connection(@site.config[:database])
      end

      def down
        # Disconnect from the database
        ActiveRecord::Base.remove_connection
      end

      def setup
        # Create tables
        schema = ActiveRecord::Schema
        schema.verbose = false
        schema.define do

          create_table :pages, :force => true do |t|
            t.column :content, :text
            t.column :path,    :string
            t.column :meta,    :text
          end

          create_table :page_defaults, :force => true do |t|
            t.column :meta, :text
          end

          create_table :layouts, :force => true do |t|
            t.column :name,      :string
            t.column :content,   :text
            t.column :extension, :string
          end

          create_table :templates, :force => true do |t|
            t.column :content,  :text
            t.column :name,     :string
            t.column :meta,     :text
          end

          create_table :code_pieces, :force => true do |t|
            t.column :name, :string
            t.column :code, :text
          end

        end

        # Create first page
        DatabasePage.create(
          :path    => '/',
          :content => "I'm a brand new root page. Please edit me!\n",
          :meta    => "# Built-in\n" +
                      "\n" +
                      "# Custom\n" +
                      "title: \"A New Root Page\"\n"
        )

        # Create page defaults
        DatabasePageDefault.create(
          :meta => "# Built-in\n" +
                   "custom_path:  none\n" +
                   "extension:    \"html\"\n" +
                   "filename:     \"index\"\n" +
                   "filters_post: []\n" +
                   "filters_pre:  []\n" +
                   "is_draft:     false\n" +
                   "layout:       \"default\"\n" +
                   "skip_output:  false\n" +
                   "\n" +
                   "# Custom\n"
        )

        # Create default layout
        DatabaseLayout.create(
          :name      => 'default',
          :content   => "<html>\n" +
                        "  <head>\n" +
                        "    <title><%= @page.title %></title>\n" +
                        "  </head>\n" +
                        "  <body>\n" +
                        "<%= @page.content %>\n" +
                        "  </body>\n" +
                        "</html>",
          :extension => '.erb'
        )

        # Create default template
        DatabaseTemplate.create(
          :name    => 'default',
          :content => 'Hi, I\'m a new page!',
          :meta    => "# Built-in\n" +
                      "\n" +
                      "# Custom\n" +
                      "title: \"A New Page\"\n"
        )

        # Create default code piece
        DatabaseCodePiece.create(
          :name => 'default',
          :code => "def html_escape(str)\n" +
                   "  str.gsub('&', '&amp;').str('<', '&lt;').str('>', '&gt;').str('\"', '&quot;')\n" +
                   "end\n" +
                   "alias h html_escape\n"
        )

        log(:high, "Set up database schema.")
      end

      ########## Loading data ##########

      def pages
        # Create Pages for each database object
        DatabasePage.find(:all).map do |page|
          # Read metadata
          hash = (YAML.load(page.meta || '') || {}).clean

          if hash[:is_draft]
            # Skip drafts
            nil
          else
            # Get page info
            extras = { :path => page.path, :uncompiled_content => page.content }

            # Return page hash
            hash.merge(extras)
          end
        end.compact
      end

      def page_defaults
        YAML.load(DatabasePageDefault.find(:first).meta) || {}
      end

      def layouts
        DatabaseLayout.find(:all).map do |layout|
          {
            :name      => layout.name,
            :content   => layout.content,
            :extension => layout.extension
          }
        end
      end

      def templates
        DatabaseTemplate.find(:all).map do |template|
          {
            :name     => template.name,
            :content  => template.content,
            :meta     => template.meta
          }
        end
      end

      def code
        DatabaseCodePiece.find(:all).map { |p| p.code }.join("\n")
      end

      ########## Creating data ##########

      def create_page(path, template)
        # Make sure path does not start or end with a slash
        sanitized_path = ('/' + path + '/').gsub(/^\/+|\/+$/, '/')

        # Make sure the page doesn't exist yet
        unless DatabasePage.find_all_by_path(sanitized_path).empty?
          error "A page named '#{sanitized_path}' already exists."
        end

        # Create page
        DatabasePage.create(
          :path    => sanitized_path,
          :content => "I'm a brand new page. Please edit me!\n",
          :meta    => "# Built-in\n\n# Custom\ntitle: A New Page\n"
        )

        log(:high, "Created page '#{sanitized_path}'.")
      end

      def create_layout(name)
        # Make sure the layout doesn't exist yet
        unless DatabaseLayout.find_all_by_name(name).empty?
          error "A layout named '#{name}' already exists."
        end

        # Create layout
        DatabaseLayout.create(
          :name      => name,
          :content   => "<html>\n" +
                        "  <head>\n" +
                        "    <title><%= @page.title %></title>\n" +
                        "  </head>\n" +
                        "  <body>\n" +
                        "<%= @page.content %>\n" +
                        "  </body>\n" +
                        "</html>",
          :extension => '.erb'
        )

        log(:high, "Created layout '#{name}'.")
      end

      def create_template(name)
        # Make sure the layout doesn't exist yet
        unless DatabaseTemplate.find_all_by_name(name).empty?
          error "A template named '#{name}' already exists."
        end

        # Create template
        DatabaseTemplate.create(
          :name    => name,
          :content => "Hi, I'm a brand new page!\n",
          :meta    => "# Built-in\n\n# Custom\ntitle: A New Page\n"
        )

        log(:high,"Created template '#{name}'.")
      end

    end

  end
end
