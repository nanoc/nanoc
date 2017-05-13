# frozen_string_literal: true

describe 'GH-795', site: true, stdio: true do
  before do
    File.write('content/items.md', 'Frozen? <%= @items.unwrap.frozen? %>!')
    File.write('content/items-view.md', 'Frozen? <%= @items.frozen? %>!')
    File.write('Rules', <<EOS)
  compile '/**/*' do
    filter :erb
    write item.identifier.without_ext + '.html'
  end
EOS
  end

  it 'freezes @items' do
    Nanoc::CLI.run(['compile'])

    expect(File.read('output/items.html')).to eql('Frozen? true!')
    expect(File.read('output/items-view.html')).to eql('Frozen? true!')
  end
end
