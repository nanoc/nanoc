def try_require(s) ; begin ; require s ; rescue LoadError ; end ; end

try_require 'rubygems'

try_require 'haml'

class String

  # Converts the string using Sass
  def sass
    Sass::Engine.new(self).render
  end

end

register_filter 'sass' do |page, pages, config|
  page.content.sass
end
