# encoding: utf-8

module Nanoc3::Helpers

  # Provides functionality for rendering layouts as partials.
  module Rendering

    include Nanoc3::Helpers::Capturing

    # Returns a string containing the rendered given layout. The given layout
    # will first be run through the matching layout rule.
    #
    # The assigns (`@item`, `@config`, …) will not be available in the
    # partial, but it is possible to pass custom assigns to the method. These
    # assigns will be made available as instance variables inside the partial.
    #
    # The method can also take a block. In this case, the content of the block
    # will be captured (using the {Nanoc3::Helpers::Capturing} helper) and
    # this content will be made available with `yield`. In other words, a
    # `yield` inside the partial will output the content of the block passed
    # to the method.
    #
    # @param [String] identifier The identifier of the layout that should be
    #   rendered
    #
    # @param [Hash] other_assigns A hash containing assigns that will be made
    #   available as instance variables in the partial
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
    # @raise [Nanoc3::Errors::UnknownLayout] if the given layout does not
    #   exist
    #
    # @return [String] The rendered partial
    def render(identifier, other_assigns={}, &block)
      # Find layout
      layout = @site.layouts.find { |l| l.identifier == identifier.cleaned_identifier }
      raise Nanoc3::Errors::UnknownLayout.new(identifier.cleaned_identifier) if layout.nil?

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
      filter_name, filter_args = @site.compiler.filter_for_layout(layout)
      raise Nanoc3::Errors::CannotDetermineFilter.new(layout.identifier) if filter_name.nil?

      # Get filter class
      filter_class = Nanoc3::Filter.named(filter_name)
      raise Nanoc3::Errors::UnknownFilter.new(filter_name) if filter_class.nil?

      # Create filter
      filter = filter_class.new(assigns)

      # Layout
      @site.compiler.stack.push(layout)
      result = filter.run(layout.raw_content, filter_args)
      @site.compiler.stack.pop

      # Append to erbout if we have a block
      if block_given?
        erbout = eval('_erbout', block.binding)
        erbout << result
      end

      # Done
      result
    end

  end

end
