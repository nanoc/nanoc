# frozen_string_literal: true

describe 'GH-833', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'stuff')
    File.write('Rules', <<EOS)
  compile '/**/*' do
    write item.identifier.without_ext + '.txt'
  end
EOS
  end

  it 'runs show-data without crashing' do
    Nanoc::CLI.run(['show-data'])
  end
end
