# frozen_string_literal: true

describe 'GH-1358', site: true, stdio: true do
  before do
    FileUtils.mkdir_p('content')
    File.write('content/foo.dat', 'hi')
    File.write('content/home.erb', '<%= File.read(@items["/foo.*"].raw_filename) %>')

    File.write('Rules', <<~EOS)
      ignore '/*.dat'

      compile '/*' do
        filter :erb
        write ext: 'html'
      end
    EOS
  end

  example do
    Nanoc::CLI.run([])
    File.write('content/foo.dat', 'hello')

    expect { Nanoc::CLI.run([]) }
      .to change { File.read('output/home.html') }
      .from('hi')
      .to('hello')
  end
end
