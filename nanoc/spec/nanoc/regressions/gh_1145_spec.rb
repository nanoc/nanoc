# frozen_string_literal: true

describe 'GH-1145', site: true, stdio: true do
  before do
    File.write('content/foo.txt', 'asdf')

    File.write('Rules', <<~EOS)
      compile '/**/*' do
        filter :erb
        write '/last.html'
      end
EOS
  end

  it 'detects missing output file of non-default rep' do
    expect { Nanoc::CLI.run(%w[--verbose]) }.to output(/erb /).to_stdout
  end
end
