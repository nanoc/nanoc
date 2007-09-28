class String

  # Converts the string using Haml
  def haml(params={})
    nanoc_require 'haml'

    options = (params[:haml_options] || {})
    options[:locals] = params[:assigns] unless params[:assigns].nil?

    Haml::Engine.new(self, options).to_html
  end

end

register_filter 'haml' do |page, pages, config|
  assigns = { :page => page, :pages => pages }
  page.content.haml(:assigns => assigns, :haml_options => page[:haml_options])
end
