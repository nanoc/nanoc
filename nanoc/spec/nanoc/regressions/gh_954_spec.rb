# frozen_string_literal: true

describe 'GH-954', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'foo <a href="/">root</a>')
    File.write('content/bar.md', 'bar <a href="/">root</a>')
    File.write('content/bar-copy.md', '<%= @items["/bar.*"].compiled_content(snapshot: :last) %>')

    File.write('Rules', <<~EOS)
      compile '/foo.*' do
        filter :relativize_paths, type: :html unless rep.path.nil?
        write item.identifier.without_ext + '.html'
      end

      compile '/bar.*' do
        filter :relativize_paths, type: :html unless rep.path.nil?
      end

      compile '/bar-copy.*' do
        filter :erb
        write item.identifier.without_ext + '.html'
      end
EOS
  end

  it 'properly filters foo.md' do
    Nanoc::CLI.run(%w[compile])

    # Path is relativized
    expect(File.read('output/foo.html')).to eq('foo <a href="./">root</a>')

    # Path is not relativized
    expect(File.read('output/bar-copy.html')).to eq('bar <a href="/">root</a>')
  end
end
