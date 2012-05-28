# encoding: utf-8

module Nanoc::Helpers

  # Provides functionality for filtering parts of an item or a layout.
  module Filtering

    require 'nanoc/helpers/capturing'
    include Nanoc::Helpers::Capturing

    # Filters the content in the given block and outputs it. This function
    # does not return anything; instead, the filtered contents is directly
    # appended to the output buffer (`_erbout`).
    #
    # This function has been tested with ERB and Haml. Other filters may not
    # work correctly.
    #
    # @example Running a filter on a part of an item or layout
    #
    #   <p>Lorem ipsum dolor sit amet...</p>
    #   <% filter :rubypants do %>
    #     <p>Consectetur adipisicing elit...</p>
    #   <% end %>
    #
    # @param [Symbol] filter_name The name of the filter to run on the
    #   contents of the block
    #
    # @param [Hash] arguments Arguments to pass to the filter
    #
    # @return [void]
    def filter(filter_name, arguments={}, &block)
      # Capture block
      data = capture(&block)

      # Find filter
      klass = Nanoc::Filter.named(filter_name)
      raise Nanoc::Errors::UnknownFilter.new(filter_name) if klass.nil?
      filter = klass.new(@item_rep.assigns)

      # Filter captured data
      Nanoc::NotificationCenter.post(:filtering_started, @item_rep, filter_name)
      filtered_data = filter.run(data, arguments)
      Nanoc::NotificationCenter.post(:filtering_ended, @item_rep, filter_name)

      # Append filtered data to buffer
      buffer = eval('_erbout', block.binding)
      buffer << filtered_data
    end

  end

end
