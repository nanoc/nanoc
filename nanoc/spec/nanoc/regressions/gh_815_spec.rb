# frozen_string_literal: true

describe 'GH-815', site: true, stdio: true do
  before do
    File.write('nanoc.yaml', "animal: \"donkey\"\n")
    File.write('content/foo.md', '<%= @config.key?(:animal) %>')
    File.write('Rules', <<EOS)
  compile '/**/*' do
    filter :erb
    write item.identifier.without_ext + '.txt'
  end
EOS
  end

  it 'handles #key? properly' do
    Nanoc::CLI.run(['compile'])

    expect(File.read('output/foo.txt')).to eql('true')
  end
end
