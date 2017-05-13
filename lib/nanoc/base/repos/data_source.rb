# frozen_string_literal: true

module Nanoc
  # Responsible for loading site data. It is the (abstract) superclass for all
  # data sources. Subclasses must at least implement the data reading methods
  # ({#items} and {#layouts}).
  #
  # Apart from the methods for loading and storing data, there are the {#up}
  # and {#down} methods for bringing up and tearing down the connection to the
  # data source. These should be overridden in subclasses. The {#loading}
  # method wraps {#up} and {#down}. {#loading} is a convenience method for the
  # more low-level methods {#use} and {#unuse}, which respectively increment
  # and decrement the reference count; when the reference count goes from 0 to
  # 1, the data source will be loaded ({#up} will be called) and when the
  # reference count goes from 1 to 0, the data source will be unloaded
  # ({#down} will be called).
  #
  # @abstract Subclasses should at least implement {#items} and {#layouts}.
  class DataSource
    # @return [String] The root path where items returned by this data source
    #   should be mounted.
    attr_reader :items_root

    # @return [String] The root path where layouts returned by this data
    #   source should be mounted.
    attr_reader :layouts_root

    # @return [Hash] The configuration for this data source. For example,
    #   online data sources could contain authentication details.
    attr_reader :config

    extend DDPlugin::Plugin

    def initialize(site_config, items_root, layouts_root, config)
      @site_config  = site_config
      @items_root   = items_root
      @layouts_root = layouts_root
      @config       = config || {}

      @references = 0
    end

    # Loads the data source when necessary (calling {#up}), yields, and
    # unloads (using {#down}) the data source when it is not being used
    # elsewhere. All data source queries and data manipulations should be
    # wrapped in a {#loading} block; it ensures that the data source is loaded
    # when necessary and makes sure the data source does not get unloaded
    # while it is still being used elsewhere.
    #
    # @return [void]
    def loading
      use
      yield
    ensure
      unuse
    end

    # Marks the data source as used by the caller.
    #
    # Calling this method increases the internal reference count. When the
    # data source is used for the first time (first {#use} call), the data
    # source will be loaded ({#up} will be called).
    #
    # @return [void]
    def use
      up if @references.zero?
      @references += 1
    end

    # Marks the data source as unused by the caller.
    #
    # Calling this method decreases the internal reference count. When the
    # reference count reaches zero, i.e. when the data source is not used any
    # more, the data source will be unloaded ({#down} will be called).
    #
    # @return [void]
    def unuse
      @references -= 1
      down if @references.zero?
    end

    # Brings up the connection to the data. Depending on the way data is
    # stored, this may not be necessary. This is the ideal place to connect to
    # the database, for example.
    #
    # Subclasses may override this method, but are not required to do so; the
    # default implementation simply does nothing.
    #
    # @return [void]
    def up; end

    # Brings down the connection to the data. This method should undo the
    # effects of the {#up} method. For example, a database connection
    # established in {#up} should be closed in this method.
    #
    # Subclasses may override this method, but are not required to do so; the
    # default implementation simply does nothing.
    #
    # @return [void]
    def down; end

    # Returns the collection of items (represented by {Nanoc::Int::Item}) in
    # this site. The default implementation simply returns an empty array.
    #
    # Subclasses should not prepend `items_root` to the item's identifiers, as
    # this will be done automatically.
    #
    # Subclasses may override this method, but are not required to do so; the
    # default implementation simply does nothing.
    #
    # @return [Enumerable] The collection of items
    def items
      []
    end

    # Returns the collection of layouts (represented by {Nanoc::Int::Layout}) in
    # this site. The default implementation simply returns an empty array.
    #
    # Subclasses should prepend `layout_root` to the layout's identifiers,
    # since this is not done automatically.
    #
    # Subclasses may override this method, but are not required to do so; the
    # default implementation simply does nothing.
    #
    # @return [Enumerable] The collection of layouts
    def layouts
      []
    end

    # Creates a new in-memory item instance. This is intended for use within
    # the {#items} method.
    #
    # @param [String, Proc] content The uncompiled item content
    #   (if it is a textual item) or the path to the filename containing the
    #   content (if it is a binary item).
    #
    # @param [Hash, Proc] attributes A hash containing this item's attributes.
    #
    # @param [String] identifier This item's identifier.
    #
    # @param [Boolean] binary Whether or not this item is binary
    #
    # @param [String, nil] checksum_data
    #
    # @param [String, nil] content_checksum_data
    #
    # @param [String, nil] attributes_checksum_data
    def new_item(content, attributes, identifier, binary: false, checksum_data: nil, content_checksum_data: nil, attributes_checksum_data: nil)
      content = Nanoc::Int::Content.create(content, binary: binary)
      Nanoc::Int::Item.new(content, attributes, identifier, checksum_data: checksum_data, content_checksum_data: content_checksum_data, attributes_checksum_data: attributes_checksum_data)
    end

    # Creates a new in-memory layout instance. This is intended for use within
    # the {#layouts} method.
    #
    # @param [String] raw_content The raw content of this layout.
    #
    # @param [Hash] attributes A hash containing this layout's attributes.
    #
    # @param [String] identifier This layout's identifier.
    #
    # @param [String, nil] checksum_data
    #
    # @param [String, nil] content_checksum_data
    #
    # @param [String, nil] attributes_checksum_data
    def new_layout(raw_content, attributes, identifier, checksum_data: nil, content_checksum_data: nil, attributes_checksum_data: nil)
      Nanoc::Int::Layout.new(raw_content, attributes, identifier, checksum_data: checksum_data, content_checksum_data: content_checksum_data, attributes_checksum_data: attributes_checksum_data)
    end
  end
end
