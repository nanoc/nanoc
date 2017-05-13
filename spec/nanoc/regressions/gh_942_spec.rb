# frozen_string_literal: true

describe 'GH-942', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'Foo!')
    File.write('Rules', <<EOS)
  compile '/foo.*' do
    write '/parent/foo'
  end
EOS

    File.open('nanoc.yaml', 'w') do |io|
      io << 'prune:' << "\n"
      io << '  auto_prune: true' << "\n"
    end
  end

  example do
    File.write('output/parent', 'Hahaaa! I am a file and not a directory!')
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/parent/foo')).to eq('Foo!')
  end
end
