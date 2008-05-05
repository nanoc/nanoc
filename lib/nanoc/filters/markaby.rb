module Nanoc::Filters
  class Markaby < Nanoc::Filter

    identifiers :markaby
    extensions  '.mab'

    def run(content)
      nanoc_require 'markaby'

      assigns = @other_assigns.merge({ :page => @page, :pages => @pages, :layouts => @layouts, :config => @config, :site => @site })

      ::Markaby::Builder.new(assigns).instance_eval(content).to_s
    end

  end
end
