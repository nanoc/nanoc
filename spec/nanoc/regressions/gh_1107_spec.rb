describe 'GH-1107', site: true, stdio: true do
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
