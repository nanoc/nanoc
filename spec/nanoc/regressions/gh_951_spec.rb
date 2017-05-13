# frozen_string_literal: true

describe 'GH-951', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'Foo!')

    File.open('nanoc.yaml', 'w') do |io|
      io << 'string_pattern_type: legacy' << "\n"
    end

    File.write('Rules', <<EOS)
  passthrough '/foo.md'
EOS
  end

  it 'copies foo.md' do
    Nanoc::CLI.run(%w[compile])

    expect(File.file?('output/foo.md')).to eq(true)
  end
end
