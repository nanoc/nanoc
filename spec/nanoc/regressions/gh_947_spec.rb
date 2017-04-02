describe 'GH-947', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'Foo!')
    File.write('Rules', <<EOS)
  compile '/foo.*' do
    write '/foo'
  end
EOS

    File.open('nanoc.yaml', 'w') do |io|
      io << 'prune:' << "\n"
      io << '  auto_prune: true' << "\n"
    end
  end

  example do
    File.write('output/foo', 'I am an older foo!')
    expect { Nanoc::CLI.run(%w[compile]) }.to output(%r{\s+update.*  output/foo$}).to_stdout
    expect(File.read('output/foo')).to eq('Foo!')
  end
end
