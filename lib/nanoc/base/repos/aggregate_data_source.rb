module Nanoc::Int
  class AggregateDataSource < Nanoc::DataSource
    def initialize(data_sources, config)
      super({}, '/', '/', {})

      @data_sources = data_sources
      @config = config
    end

    def items
      objs = @data_sources.flat_map(&:items)
      @_items ||= Nanoc::Int::IdentifiableCollection.from(objs, @config)
    end

    def layouts
      objs = @data_sources.flat_map(&:layouts)
      @_layouts ||= Nanoc::Int::IdentifiableCollection.from(objs, @config)
    end
  end
end
