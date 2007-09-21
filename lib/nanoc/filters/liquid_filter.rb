def try_require(s) ; begin ; require s ; rescue LoadError ; end ; end

try_require 'rubygems'

try_require 'liquid'

class String

  # Converts the string using Liquid
  def liquid(params={})
    Liquid::Template.parse(self).render((params[:assigns] || {}).stringify_keys)
  rescue NameError
    $stderr.puts 'ERROR: String#liquid failed (Liquid not installed?)' unless $quiet
    exit
  end

end

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

register_filter 'liquid' do |page, pages, config|
  assigns = { :page => page, :pages => pages }
  page.content.liquid(:assigns => assigns)
end
