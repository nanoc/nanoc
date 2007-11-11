class CensorFilter < Nanoc::Filter

  name :censor

  def run(content)
    content.gsub('sucks', 'rocks')
  end

end
