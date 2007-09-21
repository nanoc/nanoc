def try_require(s) ; begin ; require s ; rescue LoadError ; end ; end

try_require 'rubygems'

try_require 'bluecloth'

class String

  # Converts the string to HTML using BlueCloth/Markdown.
  def markdown
    BlueCloth.new(self).to_html
  rescue NameError
    $stderr.puts 'ERROR: String#markdown failed: BlueCloth not installed' unless $quiet
    exit
  end

end

register_filter 'markdown', 'bluecloth' do |page, pages, config|
  page.content.markdown
end
