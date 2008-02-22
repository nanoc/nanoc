module Nanoc::DataSources

  # This is the implementation of a trivial data source. It doesn't do much
  # except return bogus data. It is meant to be a very simple example of a
  # data source, and it should be quite useful for those who want to write
  # their own data sources.
  class TrivialDataSource < Nanoc::DataSource

    ########## Attributes ##########

    # DataSource.identifier defines the name for this data source. The first
    # and only argument is the data source name as a symbol.
    identifier :trivial

    ########## Preparation ##########

    # DataSource#up is run before compiling. This is the place where you
    # should initialize the data source, if necessary. You don't need to
    # implement it; you can leave it out if you don't need initialization.
    # This is the ideal place to connect to the database, for example.
    # If your data source requires any special libraries, require them here
    # using 'nanoc_require'.
    def up
    end

    # DataSource#down is run after compiling. This is where you should clean
    # up any resources you used during the site compilation. You don't need to
    # implement it; you can leave it out if there's nothing to clean up. For
    # example, this is a good place to close the connection to the database,
    # if you have one.
    def down
    end

    # DataSource#setup is run when the site is created. This is the place
    # where you should create the data source for the first time. You don't
    # need to implement it; you can leave it out if there's nothing to set up.
    # For example, if you're using a database, this is where you should create
    # the necessary tables for the data source to function properly.
    def setup
      error "Sorry. The trivial data source isn't competent enough."
    end

    ########## Loading data ##########

    # DataSource#pages returns an array of hashes that represent pages. Each
    # hash must have at least the :uncompiled_content and :path keys. You can
    # include other metadata in this hash, though.
    def pages
      [
        { :uncompiled_content => 'Hi!',          :path => '/'       },
        { :uncompiled_content => 'Hello there.', :path => '/about/' }
      ]
    end

    # Datasource#page_defaults returns a hash with default values for page
    # metadata. This hash can be anything, even an empty hash if you wish.
    def page_defaults
      { :layout => 'quux' }
    end

    # DataSource#layouts returns an array of hashes that represent layouts.
    # Each hash must have the :name, :content and :filter keys. The :filter
    # key determines the filter that will be used for processing the layout.
    def layouts
      [
        {
          :name       => 'quux',
          :content    => "<html>\n" +
                         "  <head>\n" +
                         "    <title><%= @page.title %></title>\n" +
                         "  </head>\n" +
                         "  <body>\n" +
                         "<%= @page.content %>\n" +
                         "  </body>\n" +
                         "</html>",
          :filter     => 'erb'
        }
      ]
    end

    # DataSource#templates returns an array of hashes that represent page
    # templates. These page templates are used used by DataSource#create_page
    # to create pages using a template. Each hash must have the :name key for
    # identifying the template. Apart from that, you can structure the hash
    # like you desire. I recommend having :content (for the page content) and
    # :meta (for the page metadata) keys. Note that in this example, the value
    # corresponding to the :meta key is a hash, but it could just as well have
    # been a YAML-formatted string. Just make sure that what
    # DataSource#templates serves is what DataSource#create_page expects.
    def templates
      [
        {
          :name     => 'default',
          :content  => 'Hi, I am a new page. Please edit me!',
          :meta     => { :title => 'A New Page' }
        }
      ]
    end

    # DataSource#code returns a string containing custom code which will be
    # loaded before the site is compiled. This can be code for custom filters
    # and layout processors, but pretty much any code can be put in there
    # (global helper functions are very useful). It is possible to override
    # methods of built-in nanoc classes, but doing so will likely cause
    # massive breakage, so doing so is not recommended.
    def code
      "def foo ; 'bar' ; end"
    end

    ########## Creating data ##########

    # DataSource#create_page is run when a page is created. This function
    # should create a new page with the given name and using the given
    # template. The template is a hash taken the array of hashes returned by
    # DataSource#templates, so make sure that what DataSource#templates
    # returns is what DataSource#create_page expects. This trivial data source
    # doesn't have a permanent storage, so it can't create any pages.
    def create_page(path, template)
      error "Sorry. The trivial data source isn't competent enough."
    end

    # DataSource#create_layout is run when a layout is created. This function
    # should create a new layout with the given name. This trivial data source
    # doesn't have a permanent storage, so it can't create any layouts.
    def create_layout(name)
      error "Sorry. The trivial data source isn't competent enough."
    end

    # DataSource#create_template is run when a template is created. This
    # function should create a new template with the given name. This trivial
    # data source doesn't have a permanent storage, so it can't create any
    # templates.
    def create_template(name)
      error "Sorry. The trivial data source isn't competent enough."
    end

  end

end
