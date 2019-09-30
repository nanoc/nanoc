# frozen_string_literal: true

describe 'GH-1338', site: true, stdio: true do
  before do
    File.write('lib/default.rb', <<~EOS)
      Nanoc::Filter.define(:gh_1338) do |content, params = {}|
        Dir.chdir('..')
        content.upcase
      end
    EOS

    File.write('Rules', <<~EOS)
      compile '/*' do
        filter :gh_1338
        write ext: 'html'
      end
    EOS

    File.write('content/foo.txt', 'stuff')
  end

  example do
    Nanoc::CLI.run([])
  end
end
