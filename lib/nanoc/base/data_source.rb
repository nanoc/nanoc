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

    ########## Creating/updating

    # Creates the bare minimum essentials for this data source to work. This
    # action will likely be destructive. This method should not create sample
    # data such as a default home page, a default layout, etc. For example, if
    # you're using a database, this is where you should create the necessary
    # tables for the data source to function properly.
    #
    # Subclasses must implement this method.
    def setup
      not_implemented('setup')
    end

    # Removes all data stored by this data source. This method undoes the
    # effects of the +setup+ method.
    #
    # Subclasses must implement this method.
    def destroy
      not_implemented('destroy')
    end

    # Updated the content stored in this site to a newer version. A newer
    # version of a data source may store content in a different format, and
    # this method will update the stored content to this newer format.
    #
    # Subclasses may implement this method.
    def update
    end

    ########## Pages

    # Returns the list of pages (represented by Nanoc::Page) in this site.
    # This is an abstract method implemented by the subclass.
    #
    # Subclasses must implement this method.
    def pages
      not_implemented('pages')
    end

    # Saves the given page in the data source, creating it if it doesn't exist
    # yet and updating the existing copy otherwise.
    #
    # Subclasses must implement this method.
    def save_page(page)
      not_implemented('save_page')
    end

    # Changes the path of the given page to the given new path. When changing
    # a page's path, this method must be used (save_page will not work).
    #
    # Subclasses must implement this method.
    def move_page(page, new_path)
      not_implemented('move_page')
    end

    # Removes the given page from the data source.
    #
    # Subclasses must implement this method.
    def delete_page(page)
      not_implemented('delete_page')
    end

    ########## Assets

    # Returns the list of assets (represented by Nanoc::Asset) in this site.
    # This is an abstract method implemented by the subclass.
    #
    # Subclasses must implement this method.
    def assets
      not_implemented('assets')
    end

    # Saves the given asset in the data source, creating it if it doesn't
    # exist yet and updating the existing copy otherwise.
    #
    # Subclasses must implement this method.
    def save_asset(asset)
      not_implemented('save_asset')
    end

    # Changes the path of the given asset to the given new path. When changing
    # a asset's path, this method must be used (save_asset will not work).
    #
    # Subclasses must implement this method.
    def move_asset(asset, new_path)
      not_implemented('move_asset')
    end

    # Removes the given asset from the data source.
    #
    # Subclasses must implement this method.
    def delete_asset(asset)
      not_implemented('delete_asset')
    end

    ########## Page defaults

    # Returns the page defaults (represented by Nanoc::PageDefaults) of this
    # site. This is an abstract method implemented by the subclass.
    #
    # Subclasses must implement this method.
    def page_defaults
      not_implemented('page_defaults')
    end

    # Saves the given page defaults in the data source.
    #
    # Subclasses must implement this method.
    def save_page_defaults(page_defaults)
      not_implemented('save_page_defaults')
    end

    ########## Asset defaults

    # Returns the asset defaults (represented by Nanoc::AssetDefaults) of this
    # site. This is an abstract method implemented by the subclass.
    #
    # Subclasses must implement this method.
    def asset_defaults
      not_implemented('asset_defaults')
    end

    # Saves the given asset defaults in the data source.
    #
    # Subclasses must implement this method.
    def save_asset_defaults(asset_defaults)
      not_implemented('save_asset_defaults')
    end

    ########## Layouts

    # Returns the list of layouts (represented by Nanoc::Layout) in this site.
    # This is an abstract method implemented by the subclass.
    #
    # Subclasses must implement this method.
    def layouts
      not_implemented('layouts')
    end

    # Saves the given layout in the data source, creating it if it doesn't
    # exist yet and updating the existing copy otherwise.
    #
    # Subclasses must implement this method.
    def save_layout(layout)
      not_implemented('save_layout')
    end

    # Changes the path of the given layout to the given new path. When
    # changing a layout's path, this method must be used (save_layout will not
    # work).
    #
    # Subclasses must implement this method.
    def move_layout(layout, new_path)
      not_implemented('move_layout')
    end

    # Removes the given layout from the data source.
    #
    # Subclasses must implement this method.
    def delete_layout(layout)
      not_implemented('delete_layout')
    end

    ########## Templates

    # Returns the list of templates (represented by Nanoc::Template) in this
    # site. This is an abstract method implemented by the subclass.
    #
    # Subclasses must implement this method.
    def templates
      not_implemented('templates')
    end

    # Saves the given template in the data source, creating it if it doesn't
    # exist yet and updating the existing copy otherwise.
    #
    # Subclasses must implement this method.
    def save_template(template)
      not_implemented('save_template')
    end

    # Changes the name of the given template to the given new name. When
    # changing a template's name, this method must be used (save_template will
    # not work).
    #
    # Subclasses must implement this method.
    def move_template(template, new_name)
      not_implemented('move_template')
    end

    # Removes the given template from the data source.
    #
    # Subclasses must implement this method.
    def delete_template(template)
      not_implemented('delete_template')
    end

    ########## Code

    # Returns the custom code (represented by Nanoc::Code) for this site.
    # This is an abstract method implemented by the subclass. This can be code
    # for custom filters and layout processors, but pretty much any code can
    # be put in there (global helper functions are very useful).
    #
    # Subclasses must implement this method.
    def code
      not_implemented('code')
    end

    # Saves the given code in the data source.
    #
    # Subclasses must implement this method.
    def save_code(code)
      not_implemented('save_code')
    end

  private

    def not_implemented(name)
      raise NotImplementedError.new(
        "#{self.class} does not override ##{name}, which is required for " +
        "this data source to be used."
      )
    end

  end
end
