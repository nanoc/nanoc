def try_require(s) ; begin ; require s ; rescue LoadError ; end ; end

try_require 'rubygems'

try_require 'rdoc/markup/simple_markup'
try_require 'rdoc/markup/simple_markup/to_html'

class String

  # Converts the string using RDoc
  def rdoc
    SM::SimpleMarkup.new.convert(self, SM::ToHtml.new)
  end

end

register_filter 'rdoc' do |page, pages, config|
  page.content.rdoc
end
