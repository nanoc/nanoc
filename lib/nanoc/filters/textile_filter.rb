def try_require(s) ; begin ; require s ; rescue LoadError ; end ; end

try_require 'rubygems'

try_require 'redcloth'

class String

  # Converts the string using RedCloth/Textile
  def textile
    RedCloth.new(self).to_html
  rescue NameError
    $stderr.puts 'ERROR: String#textile failed (RedCloth not installed?)' unless $quiet
    exit
  end

end

register_filter 'textile', 'redcloth' do |page, pages, config|
  page.content.textile
end
