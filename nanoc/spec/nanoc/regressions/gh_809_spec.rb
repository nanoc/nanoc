# frozen_string_literal: true

describe 'GH-809', :site, :stdio do
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

    regex = /\r  stale  ok\e\[K/
    expect { Nanoc::CLI.run(%w[check stale]) }.to output(regex).to_stdout
  end
end
