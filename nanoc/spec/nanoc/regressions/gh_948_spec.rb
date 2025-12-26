# frozen_string_literal: true

describe 'GH-948', :site, :stdio do
  before do
    File.write('content/foo.md', 'Foo!')

    File.open('nanoc.yaml', 'w') do |io|
      io << 'prune:' << "\n"
      io << '  auto_prune: true' << "\n"
    end

    FileUtils.rm_rf('output')
  end

  it 'does not crash when output dir is not present' do # rubocop:disable RSpec/NoExpectationExample
    Nanoc::CLI.run(%w[compile])
  end
end
