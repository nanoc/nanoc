# frozen_string_literal: true

module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#filtering
  module Filtering
    require 'nanoc/helpers/capturing'
    include Nanoc::Helpers::Capturing

    # @param [Symbol] filter_name
    # @param [Hash] arguments
    #
    # @return [void]
    def filter(filter_name, arguments = {}, &block)
      # Capture block
      data = capture(&block)

      # Find filter
      klass = Nanoc::Filter.named!(filter_name)

      # Create filter
      assigns = {
        item: @item,
        rep: @rep,
        item_rep: @item_rep,
        items: @items,
        layouts: @layouts,
        config: @config,
        content: @content,
      }
      filter = klass.new(assigns)

      # Filter captured data
      Nanoc::Int::NotificationCenter.post(:filtering_started, @item_rep.unwrap, filter_name)
      filtered_data = filter.setup_and_run(data, arguments)
      Nanoc::Int::NotificationCenter.post(:filtering_ended, @item_rep.unwrap, filter_name)

      # Append filtered data to buffer
      buffer = eval('_erbout', block.binding)
      buffer << filtered_data
    end
  end
end
