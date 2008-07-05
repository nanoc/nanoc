module Nanoc::Extensions

  # Nanoc::Extensions::Capturing provides a content_for method, which allows
  # content to be "captured" on one page and reused elsewhere.
  #
  # = Example
  #
  # For example, suppose you want the sidebar of your site to contain a short
  # summary of the page. You could put the summary in the meta file, but
  # that’s not possible when the summary contains eRuby. You could also put
  # the sidebar inside the actual page, but that’s not very pretty. Instead,
  # you write the summary on the page itself, but capture it, and print it in
  # the sidebar layout.
  #
  # Captured content becomes part of the page. For example, a sidebar layout
  # could look like this:
  #
  #   <div id="sidebar">
  #     <h3>Summary</h3>
  #     <%= @page.content_for_summary || '(no summary)' %>
  #   </div>
  #
  # To put something inside that content_for_summary variable, capture it
  # using the content_for function. In the about page, for example:
  #
  #   <% content_for :summary do %>
  #     <p>On this page, nanoc is introduced, blah blah.</p>
  #   <% end %>
  #
  # When the site is compiled, the sidebar of the about page will say “On
  # this page, the purpose of nanoc is described, blah blah blah,” as
  # expected.
  module Capturing

    # Captures the content inside the block into a page attribute named
    # "content_for_" followed by the given name. The content of the block
    # itself will not be outputted.
    def content_for(name, &block)
      eval("@page[:content_for_#{name.to_s}] = capture(&block)")
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
