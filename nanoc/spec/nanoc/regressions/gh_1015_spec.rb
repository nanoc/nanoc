# frozen_string_literal: true

describe 'GH-1015', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'I am foo!')

    File.write('Rules', <<EOS)
  compile '/foo.*' do
    filter :erb, stuff: self
    write 'foo.html'
  end
EOS
  end

  it 'errors' do
    expect { Nanoc::CLI.run(%w[compile --verbose]) }.to raise_exception(Nanoc::Int::ItemRepRouter::RouteWithoutSlashError)
    expect(File.file?('outputfoo.html')).not_to be
  end
end
