# frozen_string_literal: true

describe 'GH-813', site: true, stdio: true do
  before do
    File.write('nanoc.yaml', "enable_output_diff: true\n")
    File.write('content/greeting.md', 'Hallöchen!')
    File.write('Rules', <<EOS)
  compile '/**/*' do
    snapshot :donkey, path: '/donkey.html'
    filter :kramdown
  end
EOS

    Nanoc::CLI.run(['compile'])
  end

  specify 'Nanoc generates diff for proper path' do
    File.write('content/greeting.md', 'Hellosies!')
    Nanoc::CLI.run(['compile'])

    diff = File.read('output.diff')
    expect(diff).to start_with("--- output/donkey.html\n+++ output/donkey.html\n")
  end
end
