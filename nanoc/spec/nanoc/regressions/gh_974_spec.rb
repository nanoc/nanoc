# frozen_string_literal: true

describe 'GH-974', :site, :stdio do
  before do
    File.write('content/foo.md', 'foo')

    File.write('Rules', <<~EOS)
      compile '/foo.*' do
        write item.identifier
      end
    EOS
  end

  it 'writes to path corresponding to identifier' do
    Nanoc::CLI.run(%w[compile])

    expect(File.file?('output/foo.md')).to be(true)
  end
end
