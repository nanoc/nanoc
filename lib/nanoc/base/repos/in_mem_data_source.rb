# frozen_string_literal: true

module Nanoc::Int
  class InMemDataSource < Nanoc::DataSource
    attr_reader :items
    attr_reader :layouts

    def initialize(items, layouts)
      super({}, '/', '/', {})

      @items = items
      @layouts = layouts
    end
  end
end
