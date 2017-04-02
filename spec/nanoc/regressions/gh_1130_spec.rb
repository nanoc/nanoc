describe 'GH-1130', site: true, stdio: true do
  before do
    File.write('content/foo', 'asdf')

    File.write('Rules', <<EOS)
passthrough '/**/*'
EOS

    File.write('Checks', <<EOS)
check :wat do
  @items.flat_map(&:reps).map(&:raw_path)
end
EOS
  end

  it 'does not raise fiber error' do
    Nanoc::CLI.run(%w[check wat])
  end
end
