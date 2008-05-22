module Nanoc

  # Nanoc::DataSource is responsible for loading data. It is the (abstract)
  # superclass for all data sources. Subclasses must at least implement the
  # data reading methods (+pages+, +page_defaults+, +layouts+, +templates+,
  # and +code+); all other methods involving data manipulation are optional.
  #
  # Apart from the methods for loading and storing data, there are the +up+
  # and +down+ methods for bringing up and tearing down the connection to the
  # data source. These should be overridden in subclasses. The +loading+
  # method wraps +up+ and +down+.
  #
  # The +setup+ method is used for setting up a site's data source for the
  # first time. This method should be overridden in subclasses.
  class DataSource < Plugin

    # Creates a new data source for the given site.
    def initialize(site)
      @site       = site
      @references = 0
    end

    # Loads the data source when necessary (calling +up+), yields, and unloads
    # the data source when it is not being used elsewhere. All data source
    # queries and data manipulations should be wrapped in a +loading+ block;
    # it ensures that the data source is loaded when necessary and makes sure
    # the data source does not get unloaded while it is still being used
    # elsewhere.
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

    ########## Loading and unloading

    # Brings up the connection to the data. This is an abstract method
    # implemented by the subclass. Depending on the way data is stored, this
    # may not be necessary. This is the ideal place to connect to the
    # database, for example.
    #
    # Subclasses may implement this method.
    def up
    end

    # Brings down the connection to the data. This is an abstract method
    # implemented by the subclass. This method should undo the effects of
    # +up+.
    #
    # Subclasses may implement this method.
    def down
    end

    ########## Creating

    # Creates the initial data for the site. This action will likely be
    # destructive. For example, if you're using a database, this is where you
    # should create the necessary tables for the data source to function
    # properly.
    #
    # Subclasses must implement this method.
    def setup
      not_implemented('setup', :required)
    end

    ########## Pages

    # Returns the list of pages (represented by Nanoc::Page) in this site.
    # This is an abstract method implemented by the subclass.
    #
    # Subclasses must implement this method.
    def pages
      not_implemented('pages', :required)
    end

    # TODO document
    #
    # Subclasses may implement this method. Data manipulation will not be
    # possible when not implemented.
    def save_page(page)
      not_implemented('save_page', :optional)
    end

    # TODO document
    #
    # Subclasses may implement this method. Data manipulation will not be
    # possible when not implemented.
    def move_page(page, new_path)
      not_implemented('move_page', :optional)
    end

    # TODO document
    #
    # Subclasses may implement this method. Data manipulation will not be
    # possible when not implemented.
    def delete_page(page)
      not_implemented('delete_page', :optional)
    end

    ########## Page defaults

    # Returns the page defaults (represented by Nanoc::PageDefaults) of this
    # site. This is an abstract method implemented by the subclass.
    def page_defaults
      not_implemented('page_defaults', :required)
    end

    # TODO document
    #
    # Subclasses may implement this method. Data manipulation will not be
    # possible when not implemented.
    def save_page_defaults(page_defaults)
      not_implemented('save_page_defaults', :optional)
    end

    ########## Layouts

    # Returns the list of layouts (represented by Nanoc::Layout) in this site.
    # This is an abstract method implemented by the subclass.
    def layouts
      not_implemented('layouts', :required)
    end

    # TODO document
    #
    # Subclasses may implement this method. Data manipulation will not be
    # possible when not implemented.
    def save_layout(layout)
      not_implemented('save_layout', :optional)
    end

    # TODO document
    #
    # Subclasses may implement this method. Data manipulation will not be
    # possible when not implemented.
    def move_layout(layout, new_path)
      not_implemented('move_layout', :optional)
    end

    # TODO document
    #
    # Subclasses may implement this method. Data manipulation will not be
    # possible when not implemented.
    def delete_layout(layout)
      not_implemented('delete_layout', :optional)
    end

    ########## Templates

    # Returns the list of templates (represented by Nanoc::Template) in this
    # site. This is an abstract method implemented by the subclass.
    def templates
      not_implemented('templates', :required)
    end

    # TODO document
    #
    # Subclasses may implement this method. Data manipulation will not be
    # possible when not implemented.
    def save_template(template)
      not_implemented('save_template', :optional)
    end

    # TODO document
    #
    # Subclasses may implement this method. Data manipulation will not be
    # possible when not implemented.
    def move_template(template, new_path)
      not_implemented('move_template', :optional)
    end

    # TODO document
    #
    # Subclasses may implement this method. Data manipulation will not be
    # possible when not implemented.
    def delete_template(template)
      not_implemented('delete_template', :optional)
    end

    ########## Code

    # Returns the custom code (represented by Nanoc:::Code) for this site.
    # This is an abstract method implemented by the subclass. This can be code
    # for custom filters and layout processors, but pretty much any code can
    # be put in there (global helper functions are very useful).
    #
    # Subclasses must implement this method.
    def code
      not_implemented('code', :required)
    end

    # TODO document
    #
    # Subclasses may implement this method. Data manipulation will not be
    # possible when not implemented.
    def save_code(code)
      not_implemented('save_code', :optional)
    end

  private

    def not_implemented(name, kind)
      # Build message
      case kind
        when :required
          message = "#{self.class} does not override ##{name}, which is required for this data source to be used."
        when :optional
          message = "#{self.class} does not override ##{name}, which is required for the kind of functionality you requested."
      end

      # Raise exception
      raise NotImplementedError.new(message)
    end

  end
end
