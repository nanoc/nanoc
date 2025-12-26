# frozen_string_literal: true

describe 'GH-1185', :site, :stdio do
  before do
    File.write('content/foo.html', 'stuff')

    File.write('Rules', <<~EOS)
      preprocess do
        @items['/foo.*'].identifier = '/bar.html'
      end

      compile '/**/*' do
        filter :erb
        write ext: 'html'
      end
    EOS
  end

  it 'does not crash' do # rubocop:disable RSpec/NoExpectationExample
    Nanoc::CLI.run(%w[compile])
  end
end
