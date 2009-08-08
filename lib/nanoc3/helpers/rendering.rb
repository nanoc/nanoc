# encoding: utf-8

module Nanoc3::Helpers

  # Nanoc3::Helpers::Rendering provides functionality for rendering layouts as
  # partials.
  #
  # This helper is activated automatically.
  module Rendering

    include Nanoc3::Helpers::Capturing

    # Returns a string containing the rendered given layout.
    #
    # +identifier+:: the identifier of the layout that should be rendered.
    #
    # +other_assigns+:: a hash containing assigns that will be made available
    #                   as instance variables.
    #
    # Example 1: a layout 'head' with content "HEAD" and a layout 'foot' with
    # content "FOOT":
    #
    #   <%= render 'head' %> - MIDDLE - <%= render 'foot' %>
    #   # => "HEAD - MIDDLE - FOOT" 
    #
    # Example 2: a layout named 'head' with content "<h1><%= @title %></h1>":
    #
    #   <%= render 'head', :title => 'Foo' %>
    #   # => "<h1>Foo</h1>"
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
