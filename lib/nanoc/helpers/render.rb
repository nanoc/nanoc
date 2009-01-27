module Nanoc::Helpers

  # Nanoc::Helpers::Render provides functionality for rendering layouts as
  # partials.
  #
  # This helper is activated automatically.
  module Render

    # Returns a string containing the rendered given layout.
    #
    # +name_or_path+:: the name or the path of the layout that should be
    #                  rendered.
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
    def render(name_or_path, other_assigns={})
      # Find layout
      layout = @_obj.site.layouts.find { |l| l.path == name_or_path.cleaned_path }
      raise Nanoc::Errors::UnknownLayoutError.new(name_or_path.cleaned_path) if layout.nil?

      # Find filter
      klass = layout.filter_class
      raise Nanoc::Errors::CannotDetermineFilterError.new(layout.path) if klass.nil?
      filter = klass.new(@_obj_rep, other_assigns)

      # Layout
      @_obj.site.compiler.stack.push(layout)
      result = filter.run(layout.content)
      @_obj.site.compiler.stack.pop
      result
    end

  end

end

# Include by default
include Nanoc::Helpers::Render
