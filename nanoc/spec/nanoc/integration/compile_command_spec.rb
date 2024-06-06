# frozen_string_literal: true

describe 'Compile command', site: true, stdio: true do
  describe 'diff generation' do
    before do
      File.write('content/foo.md', "I am foo!\n")

      File.write('Rules', <<~EOS)
        compile '/foo.*' do
          write '/foo.html'
        end
      EOS
    end

    it 'does not generate diff by default' do
      FileUtils.mkdir_p('output')
      File.write('output/foo.html', "I am old foo!\n")

      Nanoc::CLI.run(%w[compile])

      expect(File.file?('output.diff')).not_to be
    end

    it 'honors --diff' do
      FileUtils.mkdir_p('output')
      File.write('output/foo.html', "I am old foo!\n")

      Nanoc::CLI.run(%w[compile --diff])

      expect(File.file?('output.diff')).to be
    end
  end

  it 'recompiles when changing routes' do
    # Create items
    File.write('content/a.html', '<h1>A</h1>')
    File.write('content/b.html', '<h1>B</h1>')

    # Create routes
    File.open('Rules', 'w') do |io|
      io.write "compile '**/*' do\n"
      io.write "end\n"
      io.write "\n"
      io.write "route '/a.*' do\n"
      io.write "  '/index.html'\n"
      io.write "end\n"
    end

    # Compile
    Nanoc::CLI.run(%w[compile])

    # Check
    expect(File.read('output/index.html')).to eq('<h1>A</h1>')

    # Create routes
    File.open('Rules', 'w') do |io|
      io.write "compile '**/*' do\n"
      io.write "end\n"
      io.write "\n"
      io.write "route '/b.*' do\n"
      io.write "  '/index.html'\n"
      io.write "end\n"
    end

    # Compile
    Nanoc::CLI.run(%w[compile])

    # Check
    expect(File.read('output/index.html')).to eq('<h1>B</h1>')
  end

  it 'recompiles only items under focus' do
    # Create items
    File.write('content/a.html', '<h1>A</h1>')
    File.write('content/b.html', '<h1>B</h1>')

    # Create routes
    File.write('Rules', <<~RULES)
      compile '/**/*' do
        write ext: '.html'
      end
    RULES

    # Compile
    Nanoc::CLI.run(%w[compile --focus /a.*])

    # Check
    expect(File.read('output/a.html')).to eq('<h1>A</h1>')
    expect(File.file?('output/b.html')).to be(false)
  end
end
