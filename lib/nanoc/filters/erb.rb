module Nanoc::Filters
  class ERB < Nanoc::Filter

    identifiers :erb
    extensions   '.erb', '.rhtml'

    def run(content)
      nanoc_require 'erb'

      # Create context
      assigns = @other_assigns.merge({ :page => @page, :pages => @pages, :config => @config, :site => @site })
      context = ::Nanoc::Context.new(assigns)

      # Get result
      ::ERB.new(content).result(context.get_binding)
    end

  end
end
