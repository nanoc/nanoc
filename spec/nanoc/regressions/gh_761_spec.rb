# frozen_string_literal: true

describe 'GH-761', site: true do
  before do
    File.write('content/donkey.md', 'Compiled content donkey!')

    File.write('layouts/foo.erb', '[<%= @item.compiled_content %>]')

    File.write('Rules', <<EOS)
  compile '/**/*' do
    layout '/foo.*'
    write '/donkey.html'
  end

  layout '/foo.*', :erb
EOS
  end

  it 'supports #compiled_content instead of yield' do
    site = Nanoc::Int::SiteLoader.new.new_from_cwd
    site.compile

    expect(File.read('output/donkey.html')).to eql('[Compiled content donkey!]')
  end
end
