module Nanoc::Filters
  class MarkabyFilter < Nanoc::Filter

    identifiers :markaby

    def run(content)
      nanoc_require 'markaby'

      assigns = { :page => @page, :pages => @pages, :config => @config, :site => @site }

      ::Markaby::Builder.new(assigns).instance_eval(content).to_s
    end

  end
end
