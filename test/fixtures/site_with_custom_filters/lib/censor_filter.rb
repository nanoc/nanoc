class CensorFilter < Nanoc::Filter

  names :censor

  def run(content)
    content.gsub('sucks', 'rocks')
  end

end
