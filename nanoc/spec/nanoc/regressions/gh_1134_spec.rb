# frozen_string_literal: true

describe 'GH-1134', :site, :stdio do
  before do
    File.write('content/foo.txt', 'asdf')

    File.write('Rules', <<~EOS)
      compile '/**/*' do
        write '/first.html'
        filter :erb
        write '/last.html'
      end
    EOS
  end

  it 'detects missing output file of non-default rep' do
    Nanoc::CLI.run(['compile'])
    expect(File.file?('output/first.html')).to be(true)
    expect(File.file?('output/last.html')).to be(true)

    FileUtils.rm_f('output/first.html')
    expect(File.file?('output/first.html')).to be(false)
    expect(File.file?('output/last.html')).to be(true)

    Nanoc::CLI.run(['compile'])
    expect(File.file?('output/first.html')).to be(true)
    expect(File.file?('output/last.html')).to be(true)
  end
end
