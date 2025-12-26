# frozen_string_literal: true

describe 'GH-841', :site, :stdio do
  before do
    File.write('content/foo.md', 'stuff')

    File.write('Rules', <<EOS)
  preprocess do
    items.delete_if { |_| true }
  end
EOS
  end

  it 'preprocesses before running the check' do # rubocop:disable RSpec/NoExpectationExample
    Nanoc::CLI.run(%w[check stale])
  end
end
