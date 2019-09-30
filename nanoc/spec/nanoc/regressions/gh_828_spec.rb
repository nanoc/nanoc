# frozen_string_literal: true

describe 'GH-828', site: true, stdio: true do
  before do
    File.write('content/bad.md', "---\nbad: true\n---\n\nI am bad!")
    File.write('content/good.md', "---\nbad: false\n---\n\nI am good!")
    File.write('Rules', <<EOS)
  preprocess do
    @items.delete_if { |i| i[:bad] }
  end

  compile '/**/*' do
    filter :erb
    write item.identifier.without_ext + '.txt'
  end
EOS
  end

  it 'only writes good page' do
    Nanoc::CLI.run(['compile'])

    expect(File.file?('output/good.txt')).to be
    expect(File.file?('output/bad.txt')).not_to be
  end
end
