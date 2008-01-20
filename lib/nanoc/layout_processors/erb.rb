module Nanoc::LayoutProcessors
  class ERBLayoutProcessor < Nanoc::LayoutProcessor

    identifiers  :erb, :eruby
    extensions   '.erb', '.rhtml'

    def run(layout)
      nanoc_require 'erb'

      # Create context
      assigns = @other_assigns.merge({ :page => @page, :pages => @pages, :config => @config, :site => @site })
      context = ::Nanoc::Context.new(assigns)

      # Get result
      ::ERB.new(layout).result(context.get_binding)
    end

  end
end
