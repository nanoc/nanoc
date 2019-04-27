# frozen_string_literal: true

module Nanoc
  module Core
    class InMemDataSource < Nanoc::Core::DataSource
      attr_reader :items
      attr_reader :layouts

      def initialize(items, layouts, orig_data_source = nil)
        super({}, '/', '/', {})

        @items = items
        @layouts = layouts
        @orig_data_source = orig_data_source
      end

      def item_changes
        @orig_data_source ? @orig_data_source.item_changes : super
      end

      def layout_changes
        @orig_data_source ? @orig_data_source.layout_changes : super
      end
    end
  end
end
