# encoding: utf-8

module Nanoc3

  # Nanoc3::DataSource is responsible for loading data. It is the (abstract)
  # superclass for all data sources. Subclasses must at least implement the
  # data reading methods (+items+ and +layouts+); all other methods involving
  # data manipulation are optional.
  #
  # Apart from the methods for loading and storing data, there are the +up+
  # and +down+ methods for bringing up and tearing down the connection to the
  # data source. These should be overridden in subclasses. The +loading+
  # method wraps +up+ and +down+.
  #
  # The +setup+ method is used for setting up a site's data source for the
  # first time. This method should be overridden in subclasses.
  class DataSource < Plugin

    # A string containing the root where items returned by this data source
    # should be mounted.
    attr_reader :items_root

    # A string containing the root where layouts returned by this data source
    # should be mounted.
    attr_reader :layouts_root

    # A hash containing the configuration for this data source. For example,
    # online data sources could contain authentication details.
    attr_reader :config

    # Creates a new data source for the given site.
    #
    # @param [Nanoc3::Site] site The site this data source belongs to.
    #
    # @param [String] items_root The prefix that should be given to all items
    #   returned by the #items method (comparable to mount points for
    #   filesystems in Unix-ish OSes).
    #
    # @param [String] layouts_root The prefix that should be given to all
    #   layouts returned by the #layouts method (comparable to mount points
    #   for filesystems in Unix-ish OSes).
    #
    # @param [Hash] config The configuration for this data source.
    def initialize(site, items_root, layouts_root, config)
      @site         = site
      @items_root   = items_root
      @layouts_root = layouts_root
      @config       = config

      @references = 0
    end

    # Sets the identifiers for this data source.
    def self.identifiers(*identifiers)
      Nanoc3::DataSource.register(self, *identifiers)
    end

    # Sets the identifier for this data source.
    def self.identifier(identifier)
      Nanoc3::DataSource.register(self, identifier)
    end

    # Registers the given class as a data source with the given identifier.
    def self.register(class_or_name, *identifiers)
      Nanoc3::Plugin.register(Nanoc3::DataSource, class_or_name, *identifiers)
    end

    # Loads the data source when necessary (calling +up+), yields, and unloads
    # the data source when it is not being used elsewhere. All data source
    # queries and data manipulations should be wrapped in a +loading+ block;
    # it ensures that the data source is loaded when necessary and makes sure
    # the data source does not get unloaded while it is still being used
    # elsewhere.
    def loading
      use
      yield
    ensure
      unuse
    end

    # Marks the data source as used by the caller.
    #
    # Calling this method increases the internal reference count. When the
    # data source is used for the first time (first #use call), the data
    # source will be loaded (#up will be called). Similarly, when the
    # reference count reaches zero, the data source will be unloaded (#down
    # will be called).
    def use
      up if @references == 0
      @references += 1
    end

    # Marks the data source as unused by the caller.
    #
    # Calling this method increases the internal reference count. When the
    # data source is used for the first time (first #use call), the data
    # source will be loaded (#up will be called). Similarly, when the
    # reference count reaches zero, the data source will be unloaded (#down
    # will be called).
    def unuse
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

    # Updated the content stored in this site to a newer version. A newer
    # version of a data source may store content in a different format, and
    # this method will update the stored content to this newer format.
    #
    # Subclasses may implement this method.
    def update
    end

    ########## Loading data

    # Returns the list of items (represented by Nanoc3::Item) in this site.
    # The default implementation simply returns an empty array.
    #
    # Subclasses should not prepend items_root to the item's identifiers, as
    # this will be done automatically.
    #
    # Subclasses may implement this method.
    def items
      []
    end

    # Returns the list of layouts (represented by Nanoc3::Layout) in this
    # site. The default implementation simply returns an empty array.
    #
    # Subclasses should prepend layout_root to the layout's identifiers, since
    # this is not done automatically.
    #
    # Subclasses may implement this method.
    def layouts
      []
    end

    ########## Creating data

    # Creates a new item with the given content, attributes and identifier.
    def create_item(content, attributes, identifier)
      not_implemented('create_item')
    end

    # Creates a new layout with the given content, attributes and identifier.
    def create_layout(content, attributes, identifier)
      not_implemented('create_layout')
    end

  private

    def not_implemented(name)
      raise NotImplementedError.new(
        "#{self.class} does not implement ##{name}"
      )
    end

  end
end
