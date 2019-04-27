# frozen_string_literal: true

describe 'GH-1412', site: true, stdio: true do
  before do
    FileUtils.mkdir_p('content')
    File.write('content/a.erb', 'A <%= @items["/b.*"].compiled_content %>')
    File.write('content/b.erb', 'B <%= @items["/a.*"].compiled_content %>')

    FileUtils.mkdir_p('layouts')
    File.write('layouts/default.erb', '[<%= yield %>]')

    File.write('Rules', <<~EOS)
      compile '/*' do
        layout '/default.*'
        filter :erb
        write ext: 'html'
      end

      layout '/*', :erb
    EOS
  end

  example do
    Nanoc::CLI.run([])

    expect(File.file?('output/a.html')).to be(true)
    expect(File.read('output/a.html')).to eq('[A B <%= @items["/a.*"].compiled_content %>]')
    expect(File.file?('output/b.html')).to be(true)
    expect(File.read('output/b.html')).to eq('[B A <%= @items["/b.*"].compiled_content %>]')
  end
end
