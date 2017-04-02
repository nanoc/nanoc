describe 'GH-1134', site: true, stdio: true do
  before do
    File.write('content/foo.txt', 'asdf')

    File.write('Rules', <<EOS)
compile '/**/*' do
  write '/first.html'
  filter :erb
  write '/last.html'
end
EOS
  end

  it 'detects missing output file of non-default rep' do
    Nanoc::CLI.run(%w[compile])
    expect(File.file?('output/first.html')).to be
    expect(File.file?('output/last.html')).to be

    FileUtils.rm_f('output/first.html')
    expect(File.file?('output/first.html')).not_to be
    expect(File.file?('output/last.html')).to be

    Nanoc::CLI.run(%w[compile])
    expect(File.file?('output/first.html')).to be
    expect(File.file?('output/last.html')).to be
  end
end
