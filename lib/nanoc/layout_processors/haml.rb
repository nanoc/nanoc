register_layout_processor '.haml' do |page, pages, layout, config|
  assigns      = { :page => page, :pages => pages }
  haml_options = page.haml_options.symbolize_keys
  layout.haml(:assigns => assigns, :haml_options => haml_options)
end
