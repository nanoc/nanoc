# encoding: utf-8

module Nanoc3::Helpers

  # Nanoc3::Helpers::Filtering provides a filter method, which allows parts of
  # an item to be filtered.
  #
  # For example, the following piece of code only runs the "rubypants" filter
  # on the second paragraph:
  #
  #   <p>Lorem ipsum dolor sit amet...</p>
  #   <% filter :rubypants do %>
  #     <p>Consectetur adipisicing elit...</p>
  #   <% end %>
  #
  # This helper has been tested with ERB and Haml.
  #
  # To activate this helper, +include+ it, like this:
  #
  #   include Nanoc3::Helpers::Filtering
  module Filtering

    require 'nanoc3/helpers/capturing'
    include Nanoc3::Helpers::Capturing

    # Filters the content in the given block and outputs it.
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
