module Nanoc::Helpers

  # Nanoc::Helpers::Filtering provides a filter method, which allows parts of
  # a page to be filtered.
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
  #   include Nanoc::Helpers::Filtering
  module Filtering

    # Filters the content in the given block and outputs it.
    def filter(filter_name, &block)
      # Capture block
      data = capture(&block)

      # Find filter
      filter = Nanoc::Filter.named(filter_name).new(@_obj_rep)

      # Filter captured data
      filtered_data = filter.run(data)

      # Append filtered data to buffer
      buffer = eval('_erbout', block.binding)
      buffer << filtered_data
    end

  private

    def capture(*args, &block)
      buffer = eval('_erbout', block.binding)

      pos = buffer.length
      block.call(*args)

      data = buffer[pos..-1]

      buffer[pos..-1] = ''

      data
    end

  end

end
