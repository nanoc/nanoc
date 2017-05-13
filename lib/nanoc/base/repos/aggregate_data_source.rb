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
        Nanoc::Int::IdentifiableCollection.from(objs, @config)
      end
    end

    def layouts
      @_layouts ||= begin
        objs = @data_sources.flat_map(&:layouts)
        Nanoc::Int::IdentifiableCollection.from(objs, @config)
      end
    end
  end
end
