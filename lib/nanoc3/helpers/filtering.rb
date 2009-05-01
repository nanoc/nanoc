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
  # This helper likely only works with ERB (and perhaps Erubis).
  #
  # To activate this helper, +include+ it, like this:
  #
  #   include Nanoc3::Helpers::Filtering
  module Filtering

    # Filters the content in the given block and outputs it.
    def filter(filter_name, &block)
      # Capture block
      data = capture(&block)

      # Find filter
      filter = ::Nanoc3::Filter.named(filter_name).new(@item_rep.assigns)

      # Filter captured data
      filtered_data = filter.run(data)

      # Append filtered data to buffer
      buffer = eval('_erbout', block.binding)
      buffer << filtered_data
    end

  private

    def capture(*args, &block)
      # Get erbout so far
      erbout = eval('_erbout', block.binding)
      erbout_length = erbout.length

      # Execute block
      block.call(*args)

      # Get new piece of erbout
      erbout_addition = erbout[erbout_length..-1]

      # Remove addition
      erbout[erbout_length..-1] = ''

      # Done
      erbout_addition
    end

  end

end
