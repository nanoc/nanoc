class String

  # Converts the string using RubyPants/SmartyPants
  def smartypants
    nanoc_require 'rubypants'
    RubyPants.new(self).to_html
  end

end

register_filter 'smartypants', 'rubypants' do |page, pages, config|
  page.builtin.content.smartypants
end
