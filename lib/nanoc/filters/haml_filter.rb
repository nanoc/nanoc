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
  put '==> ' + page.builtin.haml_options.inspect
  page.builtin.content.haml(:assigns => assigns, :haml_options => page.builtin.haml_options)
end
