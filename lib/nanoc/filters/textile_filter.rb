class String

  # Converts the string using RedCloth/Textile
  def textile
    nanoc_require 'redcloth'
    RedCloth.new(self).to_html
  end

end

register_filter 'textile', 'redcloth' do |page, pages, config|
  page.builtin.content.textile
end
