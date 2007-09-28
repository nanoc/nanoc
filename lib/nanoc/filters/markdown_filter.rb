class String

  # Converts the string using Markdown
  def markdown
    nanoc_require 'bluecloth'
    BlueCloth.new(self).to_html
  end

end

register_filter 'markaby' do |page, pages, config|
  page.content.markdown
end
