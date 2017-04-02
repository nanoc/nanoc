describe 'GH-1031', site: true, stdio: true do
  before do
    File.write('content/foo.md', '[<%= @items["/bar.*"].compiled_content %>]')
    File.write('content/bar.md', 'I am bar!')

    File.write('Rules', <<EOS)
  compile '/bar.*' do
    write '/bar.txt'
  end

  compile '/foo.*', rep: :default do
    write '/foo.txt'
  end

  compile '/foo.*', rep: :depz do
    filter :erb
    write '/foo_deps.txt'
  end
EOS
  end

  it 'recompiles all reps of a changed item' do
    Nanoc::CLI.run(%w[compile])
    expect(File.file?('output/bar.txt')).to be
    expect(File.file?('output/foo.txt')).to be
    expect(File.file?('output/foo_deps.txt')).to be

    File.write('Rules', <<EOS)
  compile '/bar.*' do
    write '/bar.txt'
  end

  compile '/foo.*', rep: :default do
    write '/foo-new.txt'
  end

  compile '/foo.*', rep: :depz do
    filter :erb
    write '/foo_deps.txt'
  end
EOS

    Nanoc::CLI.run(%w[compile])
    expect(File.file?('output/bar.txt')).to be
    expect(File.file?('output/foo.txt')).to be
    expect(File.file?('output/foo_deps.txt')).to be
    expect(File.read('output/foo_deps.txt')).to eq('[I am bar!]')

    File.write('content/bar.md', 'I am a newer bar!')

    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/foo_deps.txt')).to eq('[I am a newer bar!]')
  end
end
