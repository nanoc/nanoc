describe 'GH-1037', site: true, stdio: true do
  before do
    File.write('content/giraffe.md', 'I am a giraffe!')
    File.write('content/donkey.erb', '[<%= @items["/giraffe.*"].compiled_content(snapshot: :last) %>]')

    File.write('Rules', <<EOS)
  compile '/donkey.erb' do
    filter :erb
    write '/donkey.txt'
  end

  compile '/giraffe.*' do
    write '/giraffe.txt'
    write '/giraffe.md'
  end
EOS
  end

  it 'writes two files' do
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/giraffe.txt')).to eql('I am a giraffe!')
    expect(File.read('output/giraffe.md')).to eql('I am a giraffe!')
  end

  it 'has the right :last snapshot' do
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/donkey.txt')).to eql('[I am a giraffe!]')
  end
end
