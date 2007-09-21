def try_require(s) ; begin ; require s ; rescue LoadError ; end ; end

try_require 'rubygems'

try_require 'haml'

class String

  # Converts the string using Haml
  def haml(params={})
    options = (params[:haml_options] || {})
    options[:locals] = params[:assigns] unless params[:assigns].nil?
    Haml::Engine.new(self, options).to_html
  rescue NameError
    $stderr.puts 'ERROR: String#haml failed (Haml not installed?)' unless $quiet
    exit
  end

end

register_filter 'haml' do |page, pages, config|
  assigns = { :page => page, :pages => pages }
  page.content.haml(:assigns => assigns, :haml_options => page[:haml_options])
end
