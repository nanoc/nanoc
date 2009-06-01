# encoding: utf-8

module Nanoc3::Helpers

  # Nanoc3::Helpers::Capturing provides a content_for method, which allows
  # content to be "captured" on one item and reused elsewhere.
  #
  # = Example
  #
  # For example, suppose you want the sidebar of your site to contain a short
  # summary of the item. You could put the summary in the meta file, but
  # that’s not possible when the summary contains eRuby. You could also put
  # the sidebar inside the actual item, but that’s not very pretty. Instead,
  # you write the summary on the item itself, but capture it, and print it in
  # the sidebar layout.
  #
  # Captured content becomes part of the item. For example, a sidebar layout
  # could look like this:
  #
  #   <div id="sidebar">
  #     <h3>Summary</h3>
  #     <%= @item[:content_for_summary] || '(no summary)' %>
  #   </div>
  #
  # To put something inside that content_for_summary variable, capture it
  # using the content_for function. In the about item, for example:
  #
  #   <% content_for :summary do %>
  #     <p>On this item, nanoc is introduced, blah blah.</p>
  #   <% end %>
  #
  # When the site is compiled, the sidebar of the about item will say “On
  # this item, the purpose of nanoc is described, blah blah blah,” as
  # expected.
  #
  # This helper likely only works with ERB (and perhaps Erubis).
  #
  # To activate this helper, +include+ it, like this:
  #
  #   include Nanoc3::Helpers::Capturing
  module Capturing

    # Captures the content inside the block into a item attribute named
    # "content_for_" followed by the given name. The content of the block
    # itself will not be outputted.
    def content_for(name, &block)
      eval("@item[:content_for_#{name.to_s}] = capture(&block)")
    end

    # Evaluates the given block and returns the result. The block is not outputted.
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
