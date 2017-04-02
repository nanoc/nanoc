describe 'GH-981', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'I am foo!')

    File.write('Rules', <<EOS)
  compile '/foo.*' do
    filter :erb, stuff: self
    write '/foo.html'
  end
EOS
  end

  it 'creates at first' do
    expect { Nanoc::CLI.run(%w[compile --verbose]) }.to output(%r{create.*output/foo\.html$}).to_stdout
  end

  it 'skips the item on second try' do
    Nanoc::CLI.run(%w[compile])
    expect { Nanoc::CLI.run(%w[compile --verbose]) }.to output(%r{skip.*output/foo\.html$}).to_stdout
  end
end
