# frozen_string_literal: true

describe 'GH-1037', site: true, stdio: true do
  before do
    File.write('content/foo.png', 'stuff')

    File.write('Rules', <<EOS)
  compile '/*.png' do
    write '/foo-s3cr3t.png'
  end

  passthrough '/*.png'
EOS
  end

  it 'writes one file' do
    Nanoc::CLI.run(%w[compile])
    expect(Dir['output/*']).to eql(['output/foo-s3cr3t.png'])
  end
end
