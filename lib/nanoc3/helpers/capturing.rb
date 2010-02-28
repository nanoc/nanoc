# encoding: utf-8

module Nanoc3::Helpers

  # Provides functionality for “capturing” content in one place and reusing
  # this content elsewhere.
  #
  # For example, suppose you want the sidebar of your site to contain a short
  # summary of the item. You could put the summary in the meta file, but
  # that’s not possible when the summary contains eRuby. You could also put
  # the sidebar inside the actual item, but that’s not very pretty. Instead,
  # you write the summary on the item itself, but capture it, and print it in
  # the sidebar layout.
  #
  # @example Capturing content into a `content_for_summary` attribute
  #
  #   <% content_for :summary do %>
  #     <p>On this item, nanoc is introduced, blah blah.</p>
  #   <% end %>
  #
  # @example Showing captured content in a sidebar
  #
  #   <div id="sidebar">
  #     <h3>Summary</h3>
  #     <%= @item[:content_for_summary] || '(no summary)' %>
  #   </div>
  module Capturing

    # Captures the content inside the block and stores it in an item
    # attribute named `content_for_` followed by the given name. The
    # content of the block itself will not be outputted.
    #
    # @param [Symbol, String] The base name of the attribute into which the
    # content should be stored
    #
    # @return [void]
    def content_for(name, &block)
      eval("@item[:content_for_#{name.to_s}] = capture(&block)")
    end

    # Evaluates the given block and returns the result. The contents of the
    # block is not outputted.
    #
    # This function has been tested with ERB and Haml. Other filters may not
    # work correctly.
    #
    # @return [String] The captured result
    def capture(&block)
      # Get erbout so far
      erbout = eval('_erbout', block.binding)
      erbout_length = erbout.length

      # Execute block
      block.call

      # Get new piece of erbout
      erbout_addition = erbout[erbout_length..-1]

      # Remove addition
      erbout[erbout_length..-1] = ''

      # Done
      erbout_addition
    end

  end

end
