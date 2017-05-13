# frozen_string_literal: true

describe 'GH-1047', site: true, stdio: true do
  before do
    File.write('Rules', <<EOS)
  compile '/*' do
    filter :erb
    write item.identifier
  end
EOS
  end

  it 'does not reuse old content' do
    File.write('content/foo.md', 'I am old foo!')
    File.write('content/bar.md', 'I am old bar!')
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/foo.md')).to eql('I am old foo!')
    expect(File.read('output/bar.md')).to eql('I am old bar!')

    File.write('content/foo.md', 'I am foo!')
    File.write('content/bar.md', '<%= @items["/foo.*"].compiled_content %><%= raise "boom" %>')
    expect { Nanoc::CLI.run(%w[compile]) }.to raise_error(Nanoc::Int::Errors::CompilationError)
    expect(File.read('output/foo.md')).to eql('I am foo!')

    File.write('content/bar.md', '[<%= @items["/foo.*"].compiled_content %>]')
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/foo.md')).to eql('I am foo!')
    expect(File.read('output/bar.md')).to eql('[I am foo!]')
  end
end
