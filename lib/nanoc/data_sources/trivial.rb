module Nanoc::DataSource::Trivial

  # This is the implementation of a trivial data source. It doesn't do much
  # except return bogus data. It is meant to be a very simple example of a
  # data source, and it should be quite useful for those who want to write
  # their own data sources.
  class TrivialDataSource < Nanoc::DataSource

    # Nanoc::DataSource#up is run before compiling. This is the place where
    # you should initialize the data source, if necessary. You don't need to
    # implement it; you can leave it out if you don't need initialization.
    # This is the ideal place to connect to the database, for example.
    def up
    end

    # Nanoc::DataSource#down is run after compiling. This is where you should
    # clean up any resources you used during the site compilation. You don't
    # need to implement it; you can leave it out if there's nothing to clean
    # up. For example, this is a good place to close the connection to the
    # database, if you have one.
    def down
    end

    # Nanoc::DataSource#pages returns an array of hashes that represent pages.
    # Each hash must have at least the :uncompiled_content and :path keys. You
    # can include other metadata in this hash, though.
    def pages
      [
        { :uncompiled_content => 'Hi!',          :path => '/'       },
        { :uncompiled_content => 'Hello there.', :path => '/about/' }
      ]
    end

    # Nanoc::DataSource#layouts returns an array of hashes that represent
    # layouts. Each hash must have the :name, :content and :extension keys.
    # The :extension key determines the layout processor that will be used
    # (they are defined in layout_processors/*.rb).
    def layouts
      [
        {
          :name       => 'default',
          :content    => '<html><head><title><%= @page.title %></title>' +
                         '</head><body><%= @page.content %></body></html>',
          :extension  => '.erb'
        }
      ]
    end

    # TODO: Document and implement.
    def templates
      []
    end

  end

  # The register_data_source method lets nanoc know that this is a data source
  # that can be used. The first argument is a symbol identifying the data
  # source; the second argument is the class name.
  register_data_source :trivial, TrivialDataSource

end
