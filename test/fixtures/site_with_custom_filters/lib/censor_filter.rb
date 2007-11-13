class CensorFilter < Nanoc::Filter

  identifier :censor

  def run(content)
    content.gsub('sucks', 'rocks')
  end

end
