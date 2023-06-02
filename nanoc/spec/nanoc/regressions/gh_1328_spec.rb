# frozen_string_literal: true

describe 'GH-1328', site: true, stdio: true do
  before do
    FileUtils.mkdir_p('content')
    File.write('content/foo.md', <<~EOS)
      <html>
        <head>
          <title>hi</title>
        </head>
        <body>
          <a href="/b0rk">bork bork</a>
        </body>
      </html>
    EOS

    File.write('Rules', <<~EOS)
      compile '/*' do
        write ext: 'html'
        write ext: 'htm'
        write ext: 'xhtml'
      end
    EOS

    Nanoc::CLI.run([])
  end

  it 'fails check for foo.html' do
    expect { Nanoc::CLI.run(%w[check ilinks]) }
      .to raise_error(Nanoc::Core::TrivialError, 'One or more checks failed')
      .and output(%r{output/foo\.html:}).to_stdout
  end

  it 'fails check for foo.xhtml' do
    expect { Nanoc::CLI.run(%w[check ilinks]) }
      .to raise_error(Nanoc::Core::TrivialError, 'One or more checks failed')
      .and output(%r{output/foo\.xhtml:}).to_stdout
  end

  it 'fails check for foo.htm' do
    expect { Nanoc::CLI.run(%w[check ilinks]) }
      .to raise_error(Nanoc::Core::TrivialError, 'One or more checks failed')
      .and output(%r{output/foo\.htm:}).to_stdout
  end
end
