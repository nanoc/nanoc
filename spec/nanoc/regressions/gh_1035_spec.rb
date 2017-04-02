describe 'GH-1035', site: true, stdio: true do
  before do
    File.write('content/foo.md', '[<%= @items["/bar.*"].compiled_content(snapshot: :raw) %>]')
    File.write('content/bar.md', 'I am bar!')

    File.write('lib/stuff.rb', <<EOS)
Class.new(Nanoc::Filter) do
  identifier :gh_1031_text2bin
  type :text => :binary

  def run(content, params = {})
    File.write(output_filename, content)
  end
end
EOS

    File.write('Rules', <<EOS)
  compile '/bar.*' do
    filter :gh_1031_text2bin
  end

  compile '/foo.*' do
    filter :erb
    write '/foo.txt'
  end
EOS
  end

  it 'can access textual content of now-binary item' do
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/foo.txt')).to eql('[I am bar!]')
  end
end
