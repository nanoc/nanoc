module Nanoc::Extensions

  # TODO document
  module Render

    # TODO document
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
include Nanoc::Extensions::Render
