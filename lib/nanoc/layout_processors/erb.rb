class ERBContext

  def initialize(hash)
    hash.each_pair do |key, value|
      instance_variable_set('@' + key.to_s, value)
    end
  end

  def get_binding
    binding
  end

end

class String

  def erb(params={})
    nanoc_require 'erb'
    context = ERBContext.new(params[:assigns] || {})
    ERB.new(self).result(context.get_binding)
  end

end

register_layout_processor '.rhtml', '.erb' do |page, pages, layout, config|
  layout.erb(:assigns => { :page => page, :pages => pages })
end
