# frozen_string_literal: true

describe 'GH-1064', site: true, stdio: true do
  before do
    File.write('content/foo.erb', '*<%= @items["/bar.*"].compiled_content(snapshot: :pre) %>*')
    File.write('content/bar.erb', 'Bar!')

    File.write('Rules', <<EOS)
  compile '/*' do
    filter :erb
    write item.identifier
  end
EOS
  end

  it 'does not reuse old content' do
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/foo.erb')).to eql('*Bar!*')
  end
end
