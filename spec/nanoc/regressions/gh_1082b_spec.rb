describe 'GH-1082', site: true, stdio: true do
  before do
    File.write('content/a.erb', '<%= @items["/b.*"].binary? %>')
    File.write('content/b.dat', 'stuff')

    File.write('Rules', <<EOS)
  compile '/a.*' do
    filter :erb
    write item.identifier.without_ext + '.txt'
  end

  passthrough '/b.*'
EOS
  end

  it 'requires /b to be compiled first' do
    Nanoc::CLI.run(%w(compile))
    expect(File.read('output/a.txt')).to eql('true')
  end
end
