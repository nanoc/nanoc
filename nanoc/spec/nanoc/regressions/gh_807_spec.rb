# frozen_string_literal: true

describe 'GH-807', site: true, stdio: true do
  before do
    File.write('content/item.md', 'Stuff!')
    File.write('Rules', <<EOS)
  compile '/**/*' do
    filter :erb if item[:dynamic]
    write item.identifier.without_ext + '.html'
  end
EOS
  end

  it 'does not crash' do
    Nanoc::CLI.run(['compile'])

    expect(File.read('output/item.html')).to eql('Stuff!')
  end
end
