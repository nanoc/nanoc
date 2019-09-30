# frozen_string_literal: true

describe 'GH-1082', site: true, stdio: true do
  before do
    File.write('content/a.erb', '<%= @item.reps[:default].binary? %>')

    File.write('Rules', <<EOS)
  compile '/*' do
    filter :erb
    write item.identifier.without_ext + '.txt'
  end
EOS
  end

  it 'does not require any items to be compiled' do
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/a.txt')).to eql('false')
  end
end
