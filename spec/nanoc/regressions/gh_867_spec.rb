describe 'GH-867', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'stuff')

    File.write('Rules', <<EOS)
  preprocess do
    items.delete_if { |_| true }
  end
EOS
  end

  it 'preprocesses before running show-data' do
    expect { Nanoc::CLI.run(%w[show-data]) }.not_to output(/foo/).to_stdout
  end
end
