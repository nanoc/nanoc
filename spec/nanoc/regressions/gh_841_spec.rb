# frozen_string_literal: true

describe 'GH-841', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'stuff')

    File.write('Rules', <<EOS)
  preprocess do
    items.delete_if { |_| true }
  end
EOS
  end

  it 'preprocesses before running the check' do
    Nanoc::CLI.run(%w[check stale])
  end
end
