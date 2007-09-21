def try_require(s) ; begin ; require s ; rescue LoadError ; end ; end

try_require 'rubygems'

try_require 'rubypants'

class String

  # Converts the string using RubyPants/SmartyPants
  def smartypants
    RubyPants.new(self).to_html
  rescue NameError
    $stderr.puts 'ERROR: String#smartypants failed (RubyPants not installed?)' unless $quiet
    exit
  end

end

register_filter 'smartypants', 'rubypants' do |page, pages, config|
  page.content.smartypants
end
