# frozen_string_literal: true

describe 'GH-970 (show-data)', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'foo')
    File.write('content/bar.md', '<%= @items["/foo.*"].compiled_content %>')

    File.write('Rules', <<~EOS)
      compile '/foo.*' do
        write '/foo.html'
      end

      compile '/bar.*' do
        filter :erb
        write '/bar.html'
      end
EOS
  end

  before { Nanoc::CLI.run(%w[compile]) }

  it 'shows default rep outdatedness' do
    expect { Nanoc::CLI.run(%w[show-data --no-color]) }.to(
      output(/^item \/foo\.md, rep default:\n  is not outdated/).to_stdout,
    )
    expect { Nanoc::CLI.run(%w[show-data --no-color]) }.to(
      output(/^item \/bar\.md, rep default:\n  is not outdated/).to_stdout,
    )
  end

  it 'shows file as outdated after modification' do
    File.write('content/bar.md', 'JUST BAR!')

    expect { Nanoc::CLI.run(%w[show-data --no-color]) }.to(
      output(/^item \/foo\.md, rep default:\n  is not outdated/).to_stdout,
    )
    expect { Nanoc::CLI.run(%w[show-data --no-color]) }.to(
      output(/^item \/bar\.md, rep default:\n  is outdated:/).to_stdout,
    )
  end

  it 'shows file and dependencies as outdated after modification' do
    File.write('content/foo.md', 'FOO!')

    expect { Nanoc::CLI.run(%w[show-data --no-color]) }.to(
      output(/^item \/foo\.md, rep default:\n  is outdated:/).to_stdout,
    )
    expect { Nanoc::CLI.run(%w[show-data --no-color]) }.to(
      output(/^item \/bar\.md, rep default:\n  is outdated:/).to_stdout,
    )
  end
end
