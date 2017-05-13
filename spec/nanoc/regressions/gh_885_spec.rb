# frozen_string_literal: true

describe 'GH-885', site: true, stdio: true do
  before do
    File.write(
      'content/index.html',
      "<%= @items['/hello.*'].compiled_content %> - <%= Time.now.to_f %>",
    )

    File.write('Rules', <<EOS)
  preprocess do
    items.create('hi!', {}, '/hello.html')
  end

  compile '/**/*' do
    filter :erb
    write item.identifier.without_ext + '.html'
  end
EOS
  end

  example do
    Nanoc::CLI.run(%w[compile])
    before = File.read('output/index.html')

    sleep(0.1)
    Nanoc::CLI.run(%w[compile])
    after = File.read('output/index.html')
    expect(after).to eql(before)
    expect(after).to match(/\Ahi! - \d+/)
  end
end
