# encoding: utf-8

module Nanoc::Helpers

  # Provides functionality for rendering layouts as partials.
  module Rendering

    include Nanoc::Helpers::Capturing

    # Renders the given layout. The given layout will be run through the first
    # matching layout rule.
    #
    # When this method is invoked _without_ a block, the return value will be
    # the rendered layout (a string)  and `_erbout` will not be modified.
    #
    # When this method is invoked _with_ a block, an empty string will be
    # returned and the rendered content will be appended to `_erbout`. In this
    # case, the content of the block will be captured (using the
    # {Nanoc::Helpers::Capturing} helper) and this content will be made
    # available with `yield`. In other words, a `yield` inside the partial
    # will output the content of the block passed to the method.
    #
    # (For the curious: the reason why {#render} with a block has this
    # behaviour of returning an empty string and modifying `_erbout` is
    # because ERB does not support combining the `<%= ... %>` form with a
    # method call that takes a block.)
    #
    # The assigns (`@item`, `@config`, …) will be available in the partial. It
    # is also possible to pass custom assigns to the method; these assigns
    # will be made available as instance variables inside the partial.
    #
    # @param [String] identifier The identifier of the layout that should be
    #   rendered
    #
    # @param [Hash] other_assigns A hash containing extra assigns that will be
    #   made available as instance variables in the partial
    #
    # @example Rendering a head and a foot partial around some text
    #
    #   <%= render 'head' %> - MIDDLE - <%= render 'foot' %>
    #   # => "HEAD - MIDDLE - FOOT" 
    #
    # @example Rendering a head partial with a custom title
    #
    #   # The 'head' layout
    #   <h1><%= @title %></h1>
    #
    #   # The item/layout where the partial is rendered
    #   <%= render 'head', :title => 'Foo' %>
    #   # => "<h1>Foo</h1>"
    #
    # @example Yielding inside a partial
    #
    #   # The 'box' partial
    #   <div class="box">
    #     <%= yield %>
    #   </div>
    #
    #   # The item/layout where the partial is rendered
    #   <% render 'box' do %>
    #     I'm boxy! Luvz!
    #   <% end %>
    #
    #   # Result
    #   <div class="box">
    #     I'm boxy! Luvz!
    #   </div>
    #
    # @raise [Nanoc::Errors::UnknownLayout] if the given layout does not
    #   exist
    #
    # @raise [Nanoc::Errors::CannotDetermineFilter] if there is no layout
    #   rule for the given layout
    #
    # @raise [Nanoc::Errors::UnknownFilter] if the layout rule for the given
    #   layout specifies an unknown filter
    #
    # @return [String, nil] The rendered partial, or nil if this method was
    #   invoked with a block
    def render(identifier, other_assigns={}, &block)
      # Find layout
      layout = @site.layouts.find { |l| l.identifier == identifier.cleaned_identifier }
      raise Nanoc::Errors::UnknownLayout.new(identifier.cleaned_identifier) if layout.nil?

      # Visit
      Nanoc::NotificationCenter.post(:visit_started, layout)
      Nanoc::NotificationCenter.post(:visit_ended,   layout)

      # Capture content, if any
      captured_content = block_given? ? capture(&block) : nil

      # Get assigns
      assigns = {
        :content    => captured_content,
        :item       => @item,
        :item_rep   => @item_rep,
        :items      => @items,
        :layout     => layout,
        :layouts    => @layouts,
        :config     => @config,
        :site       => @site
      }.merge(other_assigns)

      # Get filter name
      filter_name, filter_args = @site.compiler.rules_collection.filter_for_layout(layout)
      raise Nanoc::Errors::CannotDetermineFilter.new(layout.identifier) if filter_name.nil?

      # Get filter class
      filter_class = Nanoc::Filter.named(filter_name)
      raise Nanoc::Errors::UnknownFilter.new(filter_name) if filter_class.nil?

      # Create filter
      filter = filter_class.new(assigns)

      begin
        # Notify start
        Nanoc::NotificationCenter.post(:processing_started, layout)

        # Layout
        result = filter.run(layout.raw_content, filter_args)

        # Append to erbout if we have a block
        if block_given?
          # Append result and return nothing
          erbout = eval('_erbout', block.binding)
          erbout << result
          ''
        else
          # Return result
          result
        end
      ensure
        # Notify end
        Nanoc::NotificationCenter.post(:processing_ended, layout)
      end
    end

  end

end
