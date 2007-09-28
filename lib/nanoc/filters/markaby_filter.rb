class String

  # Converts the string using Markaby
  # TODO perhaps add support for helpers
  def markaby(params={})
    nanoc_require 'markaby'
    Markaby::Builder.new((params[:assigns] || {})).instance_eval(self).to_s
  end

end

register_filter 'markaby' do |page, pages, config|
  assigns = { :page => page, :pages => pages }
  page.content.markaby(:assigns => assigns)
end
