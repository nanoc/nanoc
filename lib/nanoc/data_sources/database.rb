try_require 'active_record'

module Nanoc::DataSource::Database

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

    def up
      nanoc_require 'active_record'

      # Connect to the database
      ActiveRecord::Base.establish_connection(@site.config[:database])
    end

    def down
      # Disconnect from the database
      ActiveRecord::Base.remove_connection
    end

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
          extras  = { :path => page.path, :uncompiled_content => page.content }

          # Add to list of pages
          pages + [ hash.merge(extras) ]
        end
      end
    end

    # TODO implement
    def layouts
      []
    end

    # TODO implement
    def templates
      []
    end

  end

  register_data_source :database, DatabaseDataSource

end
