register_layout_processor '.rhtml', '.erb' do |page, pages, layout, config|
  assigns = { :page => page, :pages => pages }
  layout.erb(:assigns => assigns)
end
