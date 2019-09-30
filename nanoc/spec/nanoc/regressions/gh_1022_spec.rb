# frozen_string_literal: true

describe 'GH-1022', site: true, stdio: true do
  before do
    File.write('content/ubuntu-16.10-server-amd64.iso.txt', 'torrent contents')
    File.write('content/ubuntu-16.10-server-amd64.iso.yaml', 'distro: Ubuntu')

    File.write('layouts/default.erb', '<%= @item[:distro] %> / <%= yield %>')

    File.write('Rules', <<EOS)
  compile '/**/*' do
    layout '/default.*'
    write item.identifier
  end

  layout '/*.erb', :erb
EOS
  end

  it 'recompiles all reps of a changed item' do
    Nanoc::CLI.run(%w[compile])

    expect(File.file?('output/ubuntu-16.10-server-amd64.iso.txt')).to be
    expect(File.read('output/ubuntu-16.10-server-amd64.iso.txt')).to eq('Ubuntu / torrent contents')
  end
end
