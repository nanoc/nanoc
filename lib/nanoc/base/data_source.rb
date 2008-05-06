module Nanoc

  # Nanoc::DataSource is responsible for loading data. It is the (abstract)
  # superclass for all data sources. Most methods have not been documented
  # here; instead, they are documented in the nanoc manual.
  class DataSource < Plugin

    # Creates a new data source for the given site.
    def initialize(site)
      @site       = site
      @references = 0
    end

    # Loads the data source when necessary (calling +up+), yields, and
    # unlaods the data source when it is not being used elsewhere. Always use
    # this method when accessing the data source; it ensures that the data
    # source does not get unloaded while it is still being used elsewhere.
    def loading
      # Load if necessary
      up if @references == 0
      @references += 1

      yield
    ensure
      # Unload if necessary
      @references -= 1
      down if @references == 0
    end

    def up
    end

    def down
    end

    def setup
    end

    def pages
      error 'DataSource#pages must be overridden'
    end

    def page_defaults
      error 'DataSource#page_defaults must be overridden'
    end

    def layouts
      error 'DataSource#layouts must be overridden'
    end

    def templates
      error 'DataSource#templates must be overridden'
    end

    def code
      error 'DataSource#code must be overridden'
    end

    def create_page(name, template)
      error 'DataSource#create_page must be overridden'
    end

    def create_layout(name)
      error 'DataSource#create_layout must be overridden'
    end

    def create_template(name)
      error 'DataSource#create_template must be overridden'
    end

  end
end
