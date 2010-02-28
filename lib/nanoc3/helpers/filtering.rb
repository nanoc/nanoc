# encoding: utf-8

module Nanoc3::Helpers

  # Provides functionality for filtering parts of an item or a layout.
  module Filtering

    require 'nanoc3/helpers/capturing'
    include Nanoc3::Helpers::Capturing

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
    # contents of the block
    #
    # @param [Hash] argument Arguments to pass to the filter
    #
    # @return [void]
    def filter(filter_name, arguments={}, &block)
      # Capture block
      data = capture(&block)

      # Find filter
      klass = Nanoc3::Filter.named(filter_name)
      raise Nanoc3::Errors::UnknownFilter.new(filter_name) if klass.nil?
      filter = klass.new(@item_rep.assigns)

      # Filter captured data
      filtered_data = filter.run(data, arguments)

      # Append filtered data to buffer
      buffer = eval('_erbout', block.binding)
      buffer << filtered_data
    end

  end

end
