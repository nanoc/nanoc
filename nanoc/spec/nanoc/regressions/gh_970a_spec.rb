# frozen_string_literal: true

describe 'GH-970 (show-rules)', :site, :stdio do
  before do
    File.write('content/foo.md', 'foo')

    File.write('Rules', <<~EOS)
      compile '/foo.*' do
        write '/donkey.html'
      end
    EOS
  end

  it 'shows reps' do
    expect { Nanoc::CLI.run(%w[show-rules --no-color]) }.to(
      output(%r{^Item /foo\.md:\n  Rep default: /foo\.\*$}).to_stdout,
    )
  end
end
