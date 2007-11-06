class String

  # Converts the string using Sass
  def sass
    nanoc_require 'haml'
    Sass::Engine.new(self).render
  end

end

register_filter 'sass' do |page, pages, config|
  page.builtin.content.sass
end
