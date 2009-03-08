module Nanoc::Helpers

  # Nanoc::Helpers::Render provides functionality for rendering layouts as
  # partials.
  #
  # This helper is activated automatically.
  module Render

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
    def render(identifier, other_assigns={})
      # Find layout
      layout = @site.layouts.find { |l| l.identifier == identifier.cleaned_identifier }
      raise Nanoc::Errors::UnknownLayoutError.new(identifier.cleaned_identifier) if layout.nil?

      # Get assigns
      assigns = {
        :_obj_rep   => @_obj_rep,
        :_obj       => @_obj,
        :page_rep   => @page_rep,
        :page       => @page,
        :asset_rep  => @asset_rep,
        :asset      => @asset,
        :layout     => layout.to_proxy,
        :pages      => @pages,
        :assets     => @assets,
        :layouts    => @layouts,
        :config     => @config,
        :site       => @site
      }.merge(other_assigns)

      # Create filter
      filter_class = @site.compiler.filter_class_for_layout(layout)
      filter = filter_class.new(assigns)

      # Layout
      @site.compiler.stack.push(layout)
      result = filter.run(layout.content)
      @site.compiler.stack.pop
      result
    end

  end

end
