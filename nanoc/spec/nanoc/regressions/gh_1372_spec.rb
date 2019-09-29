# frozen_string_literal: true

describe 'GH-1372', site: true, stdio: true do
  before do
    FileUtils.mkdir_p('content')
    File.write('content/home.erb', 'hello')

    FileUtils.mkdir_p('layouts')
    File.write('layouts/default.haml', '#main= yield')

    File.write('Rules', <<~EOS)
      compile '/*' do
        layout '/default.*'
        write ext: 'html'
      end

      layout '/**/*', :haml, remove_whitespace: false
    EOS
  end

  example do
    Nanoc::OrigCLI.run(['--verbose'])

    File.write('Rules', <<~EOS)
      compile '/*' do
        layout '/default.*'
        write ext: 'html'
      end

      layout '/**/*', :haml, remove_whitespace: true
    EOS

    expect { Nanoc::OrigCLI.run(['--verbose']) }
      .to output(%r{update.*output/home\.html$}).to_stdout
  end
end
