describe 'GH-813', site: true, stdio: true do
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

  specify 'Nanoc generates diff for proper path' do
    Nanoc::CLI.run(['compile'])

    expect(File.read('output/foo.txt')).to eql('true')
  end
end
