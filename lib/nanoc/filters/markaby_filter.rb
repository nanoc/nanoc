def try_require(s) ; begin ; require s ; rescue LoadError ; end ; end

try_require 'rubygems'

require 'erb'

try_require 'markaby'

class String

  # Converts the string using Markaby
  # TODO perhaps add support for helpers
  def markaby(params={})
    Markaby::Builder.new((params[:assigns] || {})).instance_eval(self).to_s
  rescue NameError
    $stderr.puts 'ERROR: String#markaby failed (Markaby not installed?)' unless $quiet
    exit
  end

end

register_filter 'markaby' do |page, pages, config|
  assigns = { :page => page, :pages => pages }
  page.content.markaby(:assigns => assigns)
end
