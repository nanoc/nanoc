register_layout_processor '.rhtml', '.erb' do |page, pages, layout, config|
  layout.erb(:assigns => { :page => page, :pages => pages })
end
