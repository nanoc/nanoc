# frozen_string_literal: true

module Nanoc::Int
  class PrefixedDataSource < Nanoc::DataSource
    def initialize(data_source, items_prefix, layouts_prefix)
      super({}, '/', '/', {})

      @data_source = data_source
      @items_prefix = items_prefix
      @layouts_prefix = layouts_prefix
    end

    def items
      @data_source.items.map { |d| d.with_identifier_prefix(@items_prefix) }
    end

    def layouts
      @data_source.layouts.map { |d| d.with_identifier_prefix(@layouts_prefix) }
    end

    def item_changes
      @data_source.item_changes
    end

    def layout_changes
      @data_source.layout_changes
    end
  end
end
