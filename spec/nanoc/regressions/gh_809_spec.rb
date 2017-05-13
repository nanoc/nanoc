# frozen_string_literal: true

describe 'GH-809', site: true, stdio: true do
  before do
    File.write('content/greeting.md', 'Hallöchen!')
    File.write('Rules', <<EOS)
  compile '/**/*' do
    snapshot :something, path: '/greeting.tmp'
  end
EOS
  end

  specify 'stale check does not consider output/greeting.tmp as stale' do
    Nanoc::CLI.run(['compile'])

    regex = /Running check stale…   (\e\[32m)?ok(\e\[0m)?/
    expect { Nanoc::CLI.run(%w[check stale]) }.to output(regex).to_stdout
  end
end
