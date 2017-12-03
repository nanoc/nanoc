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
end
