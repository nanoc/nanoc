# frozen_string_literal: true

describe 'GH-891', site: true, stdio: true do
  before do
    File.write('layouts/foo.erb', 'giraffes? <%= yield %>')
    File.write('Rules', <<EOS)
  preprocess do
    items.create('yes!', {}, '/hello.html')
  end

  compile '/**/*' do
    layout '/foo.*'
    write item.identifier.without_ext + '.html'
  end

  layout '/foo.*', :erb
EOS
  end

  example do
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/hello.html')).to include('giraffes?')

    File.write('layouts/foo.erb', 'donkeys? <%= yield %>')
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/hello.html')).to include('donkeys?')
  end
end
