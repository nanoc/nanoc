# frozen_string_literal: true

describe 'GH-1102', site: true, stdio: true do
  before do
    File.write('content/index.html', '<%= "things" %>')

    File.write('Rules', <<EOS)
  compile '/**/*.html' do
    filter :erb
    write item.identifier.to_s
  end
EOS
  end

  before do
    Nanoc::OrigCLI.run(%w[compile])
  end

  it 'does not output filename more than once' do
    regex = /skip.*index\.html.*skip.*index\.html/m
    expect { Nanoc::OrigCLI.run(%w[compile --verbose]) }.not_to output(regex).to_stdout
  end

  it 'outputs filename' do
    regex = /skip.*index\.html/
    expect { Nanoc::OrigCLI.run(%w[compile --verbose]) }.to output(regex).to_stdout
  end
end
