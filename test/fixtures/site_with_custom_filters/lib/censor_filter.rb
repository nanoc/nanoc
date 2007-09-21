register_filter 'censor' do |page, pages, config|
  page.content.gsub('sucks', 'rocks')
end
