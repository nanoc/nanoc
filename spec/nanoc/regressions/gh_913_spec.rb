# frozen_string_literal: true

describe 'GH-913', site: true, stdio: true do
  before do
    File.write('content/hello.html', 'hi!')

    File.write('Rules', <<EOS)
  postprocess do
    items.map(&:compiled_content)
  end

  compile '/**/*' do
    write item.identifier.without_ext + '.html'
  end

  layout '/foo.*', :erb
EOS
  end

  example do
    2.times do
      Nanoc::CLI.run(%w[compile])
      expect(File.read('output/hello.html')).to eq('hi!')
    end
  end
end
