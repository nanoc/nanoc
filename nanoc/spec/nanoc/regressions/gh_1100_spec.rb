# frozen_string_literal: true

describe 'GH-1100', site: true, stdio: true do
  before do
    File.write('content/index.html', '<% @items["stuff"] %>')

    File.write('Rules', <<EOS)
  preprocess do
    @items.delete_if { |i| false }
  end

  compile '/**/*.html' do
    filter :erb
    write item.identifier.to_s
  end
EOS
  end

  it 'should not crash' do
    Nanoc::CLI.run(%w[compile])
  end
end
