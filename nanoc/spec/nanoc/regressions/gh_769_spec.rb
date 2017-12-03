# frozen_string_literal: true

describe 'GH-769', site: true do
  before do
    File.write('content/index.md', 'Index!')
    File.write('content/donkey.md', 'Donkey! [<%= @item.parent.identifier %>]')

    File.open('nanoc.yaml', 'w') do |io|
      io << 'string_pattern_type: legacy' << "\n"
      io << 'data_sources:' << "\n"
      io << '  -' << "\n"
      io << '    type: filesystem' << "\n"
      io << '    identifier_type: legacy' << "\n"
    end

    File.write('Rules', <<EOS)
  compile '*' do
    filter :erb
    write item.identifier + 'index.html'
  end

  layout '/foo.*', :erb
EOS
  end

  it 'finds the parent if the parent is root' do
    site = Nanoc::Int::SiteLoader.new.new_from_cwd
    site.compile

    expect(File.read('output/donkey/index.html')).to eql('Donkey! [/]')
  end
end
