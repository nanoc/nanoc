class String

  # Converts the string using RDoc
  def rdoc
    nanoc_require 'rdoc/markup/simple_markup'
    nanoc_require 'rdoc/markup/simple_markup/to_html'

    SM::SimpleMarkup.new.convert(self, SM::ToHtml.new)
  end

end

register_filter 'rdoc' do |page, pages, config|
  page.builtin.content.rdoc
end
