register_layout_processor '.mab' do |page, pages, layout, config|
  assigns = { :page => page, :pages => pages }
  layout.markaby(:assigns => assigns)
end
