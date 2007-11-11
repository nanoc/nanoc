module Nanoc::DataSource::Database

  ########## Helper classes ##########

  begin

    # Represents a page in the database
    class DatabasePage < ActiveRecord::Base
      set_table_name 'pages'
    end

    # Represents a template in the database
    class DatabaseTemplate < ActiveRecord::Base
      set_table_name 'templates'
    end

    # Represents a layout in the database
    class DatabaseLayout < ActiveRecord::Base
      set_table_name 'layouts'
    end

  rescue NameError
  end

  class DatabaseDataSource < Nanoc::DataSource

    ########## Attributes ##########

    name     :database

    requires 'active_record'

    ########## Initialization ##########

    def up
      # Connect to the database
      ActiveRecord::Base.establish_connection(@site.config[:database])
    end

    def down
      # Disconnect from the database
      ActiveRecord::Base.remove_connection
    end

    def setup
      # Create tables
      ActiveRecord::Schema.define do

        create_table :pages, :force => true do |t|
          t.column :content, :text
          t.column :path,    :string
          t.column :meta,    :text
        end

        create_table :layouts, :force => true do |t|
          t.column :name,       :string
          t.column :content,    :text
          t.column :extension,  :string
        end

        create_table :templates, :force => true do |t|
        end

      end

      # Create first page
      DatabasePage.create(
        :path    => '/',
        :content => 'This is a sample root page. Please edit me!',
        :meta    => "# Built-in\n\n# Custom\ntitle: A New Page\n"
      )

      # Create default layout
      DatabaseLayout.create(
        :name       => 'default',
        :content    => '<html><head><title><%= @page.title %></title>' +
                       '</head><body><%= @page.content %></body></html>',
        :extension  => '.erb'
      )

      # Create default template
      #TODO
    end

    ########## Loading data ##########

    def pages
      # Create Pages for each database object
      DBPage.find(:all).inject([]) do |pages, page|
        # Read metadata
        hash = (YAML.load(page.meta || '') || {}).clean

        if hash[:is_draft]
          # Skip drafts
          pages
        else
          # Get extra info
          extras = { :path => page.path, :uncompiled_content => page.content }

          # Add to list of pages
          pages + [ hash.merge(extras) ]
        end
      end
    end

    # TODO implement
    def page_defaults
      {}
    end

    # TODO implement
    def layouts
      []
    end

    # TODO implement
    def templates
      []
    end

    ########## Creating data ##########

    # TODO: implement
    def create_page(name, template_name)
    end

    # TODO: implement
    def create_layout(name)
    end

    # TODO: implement
    def create_template(name)
    end

  end

  register_data_source DatabaseDataSource

end
