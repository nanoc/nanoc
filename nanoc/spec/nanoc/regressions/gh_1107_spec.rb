# frozen_string_literal: true

describe 'GH-1107', :site, :stdio do
  before do
    File.write('Rules', <<EOS)
  compile '/**/*.html' do
    garbage(data/**/*)
  end
EOS
  end

  it 'raises the proper exception' do
    expect { Nanoc::CLI.run(%w[compile --verbose]) }.to raise_error(SyntaxError)
  end
end
