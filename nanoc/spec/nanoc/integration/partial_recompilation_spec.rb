# frozen_string_literal: true

describe 'Partial recompilation', :site, :stdio do
  example do
    File.write('content/foo.md', "---\ntitle: hello\n---\n\nfoo")
    File.write('content/bar.md', '<%= @items["/foo.*"].compiled_content %><% raise "boom" %>')

    File.write('Rules', <<~EOS)
      compile '/foo.*' do
        write '/foo.html'
      end

      compile '/bar.*' do
        filter :erb
        write '/bar.html'
      end
    EOS

    expect(File.file?('output/foo.html')).to be(false)
    expect(File.file?('output/bar.html')).to be(false)

    expect { Nanoc::CLI.run(['show-data', '--no-color']) }
      .to(output(%r{^item /foo\.md, rep default:\n  is outdated:}).to_stdout)
    expect { Nanoc::CLI.run(['show-data', '--no-color']) }
      .to(output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout)

    expect { Nanoc::CLI.run(['compile', '--verbose']) rescue nil }
      .to output(%r{create.*output/foo\.html}).to_stdout

    expect { Nanoc::CLI.run(['show-data', '--no-color']) }
      .to(output(%r{^item /foo\.md, rep default:\n  is not outdated}).to_stdout)
    expect { Nanoc::CLI.run(['show-data', '--no-color']) }
      .to(output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout)

    expect(File.file?('output/foo.html')).to be(true)
    expect(File.file?('output/bar.html')).to be(false)

    File.write('content/bar.md', '<% raise "boom" %>')

    expect { Nanoc::CLI.run(['compile', '--verbose', '--debug']) rescue nil }
      .not_to output(%r{output/foo\.html}).to_stdout

    expect { Nanoc::CLI.run(['show-data', '--no-color']) }
      .to(output(%r{^item /foo\.md, rep default:\n  is not outdated}).to_stdout)
    expect { Nanoc::CLI.run(['show-data', '--no-color']) }
      .to(output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout)
  end

  it 'supports moving/renaming files' do
    File.write('content/aaa.md', "---\ntitle: hello\n---\n\naaa")
    File.write('content/bbb.md', 'aaa=<%= @items["/aaa.*"].compiled_content %>')

    File.write('Rules', <<~EOS)
      compile '/*' do
        filter :erb
        write ext: 'html'
      end
    EOS

    expect(File.file?('output/aaa.html')).to be(false)
    expect(File.file?('output/bbb.html')).to be(false)

    Nanoc::CLI.run(['compile', '--verbose'])

    expect(File.file?('output/aaa.html')).to be(true)
    expect(File.file?('output/bbb.html')).to be(true)
    expect(File.file?('output/ccc.html')).to be(false)
    expect(File.read('output/aaa.html')).to eq('aaa')
    expect(File.read('output/bbb.html')).to eq('aaa=aaa')

    FileUtils.mv('content/bbb.md', 'content/ccc.md')
    Nanoc::CLI.run(['compile', '--verbose'])
    Nanoc::CLI.run(['prune', '--yes'])

    expect(File.file?('output/aaa.html')).to be(true)
    expect(File.file?('output/bbb.html')).to be(false)
    expect(File.file?('output/ccc.html')).to be(true)
    expect(File.read('output/aaa.html')).to eq('aaa')
    expect(File.read('output/ccc.html')).to eq('aaa=aaa')

    FileUtils.mv('content/ccc.md', 'content/bbb.md')
    Nanoc::CLI.run(['compile', '--verbose'])
    Nanoc::CLI.run(['prune', '--yes'])

    expect(File.file?('output/aaa.html')).to be(true)
    expect(File.file?('output/bbb.html')).to be(true)
    expect(File.file?('output/ccc.html')).to be(false)
    expect(File.read('output/aaa.html')).to eq('aaa')
    expect(File.read('output/bbb.html')).to eq('aaa=aaa')
  end
end
