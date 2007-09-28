# Filter

class String

  def liquid(params={})
    nanoc_require 'liquid'

    Liquid::Template.parse(self).render((params[:assigns] || {}).stringify_keys)
  end

end

register_filter 'liquid' do |page, pages, config|
  assigns = { :page => page, :pages => pages }
  page.content.liquid(:assigns => assigns)
end

# Render tag

begin
  class Nanoc::LiquidRenderTag < ::Liquid::Tag
    Syntax = /(['"])([^'"]+)\1/

    def initialize(markup, tokens)
      if markup =~ Syntax
        @layout_name = $2
      else
        raise SyntaxError.new("Error in tag 'render' - Valid syntax: render '[layout]'")
      end

      super
    end

    def parse(tokens)
    end

    def render(context)
      source  = File.read('layouts/' + @layout_name + '.liquid')
      partial = Liquid::Template.parse(source)

      partial.render(context)
    end
  end

  Liquid::Template.register_tag('render', Nanoc::LiquidRenderTag)
rescue NameError
end
