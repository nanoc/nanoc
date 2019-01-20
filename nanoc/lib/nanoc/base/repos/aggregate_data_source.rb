# frozen_string_literal: true

module Nanoc::Int
  class AggregateDataSource < Nanoc::DataSource
    def initialize(data_sources, config)
      super({}, '/', '/', {})

      @data_sources = data_sources
      @config = config
    end

    def items
      @_items ||= begin
        objs = @data_sources.flat_map(&:items)
        Nanoc::Core::ItemCollection.new(@config, objs)
      end
    end

    def layouts
      @_layouts ||= begin
        objs = @data_sources.flat_map(&:layouts)
        Nanoc::Core::LayoutCollection.new(@config, objs)
      end
    end

    def item_changes
      SlowEnumeratorTools.merge(@data_sources.map(&:item_changes))
    end

    def layout_changes
      SlowEnumeratorTools.merge(@data_sources.map(&:layout_changes))
    end
  end
end
