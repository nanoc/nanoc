# frozen_string_literal: true

describe 'GH-1097', site: true, stdio: true do
  before do
    File.write('content/a.dat', 'foo')
    File.write('content/index.html', '<%= @items.find_all("/*.dat").flat_map(&:reps).all? { |r| File.file?(r.raw_path) } %>')
    File.write('content/z.dat', 'quux')

    File.write('Rules', <<EOS)
  compile '/**/*.html' do
    filter :erb
    write item.identifier.to_s
  end

  passthrough '/**/*.dat'
EOS
  end

  it 'generates dependency on all reps' do
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/index.html')).to eql('true')
  end
end
