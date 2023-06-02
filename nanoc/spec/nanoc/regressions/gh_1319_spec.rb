# frozen_string_literal: true

describe 'GH-1319', site: true, stdio: true do
  before do
    File.write('content/stuff.html', '<gcse:search>abc</gcse:search>')

    File.write('Rules', <<~EOS)
      compile '/**/*' do
        filter :relativize_paths, type: :html
        write ext: 'html'
      end
    EOS

    Nanoc::CLI.run(%w[compile])
  end

  example do
    expect(File.read('output/stuff.html')).to eq('<gcse:search>abc</gcse:search>')
  end
end
