# frozen_string_literal: true

describe 'Outdatedness integration', :site, :stdio do
  context 'only attribute dependency' do
    let(:time) { Time.now }

    before do
      File.write('content/foo.md', "---\ntitle: hello\n---\n\nfoo")
      File.write('content/bar.md', '<%= @items["/foo.*"][:title] %>')

      FileUtils.touch('content/foo.md', mtime: time)
      FileUtils.touch('content/bar.md', mtime: time)

      File.write('Rules', <<~EOS)
        compile '/foo.*' do
          write '/foo.html'
        end

        compile '/bar.*' do
          filter :erb
          write '/bar.html'
        end
      EOS

      Nanoc::CLI.run(['compile'])
    end

    it 'shows default rep outdatedness' do
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is not outdated}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is not outdated}).to_stdout,
      )
    end

    it 'shows file as outdated after modification' do
      File.write('content/bar.md', 'JUST BAR!')
      FileUtils.touch('content/bar.md', mtime: time)

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is not outdated}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout,
      )
    end

    it 'shows file and dependencies as not outdated after content modification' do
      File.write('content/foo.md', "---\ntitle: hello\n---\n\nfoooOoooOOoooOooo")
      FileUtils.touch('content/foo.md', mtime: time)

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is outdated:}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is not outdated}).to_stdout,
      )
    end

    it 'shows file and dependencies as outdated after title modification' do
      File.write('content/foo.md', "---\ntitle: bye\n---\n\nfoo")
      FileUtils.touch('content/foo.md', mtime: time)

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is outdated:}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout,
      )
    end
  end

  context 'only attribute dependency on config' do
    let(:time) { Time.now }

    before do
      File.write('content/bar.md', '<%= @config[:title] %>')

      FileUtils.touch('content/bar.md', mtime: time)

      File.write('nanoc.yaml', <<~EOS)
        title: The Original
      EOS

      File.write('Rules', <<~EOS)
        compile '/foo.*' do
          write '/foo.html'
        end

        compile '/bar.*' do
          filter :erb
          write '/bar.html'
        end
      EOS

      Nanoc::CLI.run(['compile'])
    end

    it 'shows default rep outdatedness' do
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is not outdated}).to_stdout,
      )
    end

    it 'shows file as outdated after modification' do
      File.write('content/bar.md', 'JUST BAR!')
      FileUtils.touch('content/bar.md', mtime: time)

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout,
      )
    end

    it 'shows file and dependencies as outdated after title modification' do
      File.write('nanoc.yaml', 'title: Totes Newz')
      FileUtils.touch('nanoc.yaml', mtime: time)

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout,
      )
    end
  end

  context 'attribute dependency on an item collection' do
    let(:time) { Time.now }

    around do |example|
      Nanoc::Core::Feature.enable('where') { example.run }
    end

    before do
      File.write('content/nanoc.md', "---\ntitle: Nanoc\nkind: bork\n---\n")
      File.write(
        'content/index.erb',
        '<% @items.where(kind: "work").each do |item| %><%= item[:title] %><% end %>',
      )

      FileUtils.touch('content/nanoc.md', mtime: time)
      FileUtils.touch('content/index.erb', mtime: time)

      File.write('Rules', <<~EOS)
        compile '/nanoc.md' do
          write '/work.html'
        end

        compile '/index.erb' do
          filter :erb
          write '/index.html'
        end
      EOS

      Nanoc::CLI.run(['compile'])
    end

    it 'recompiles correctly when an item enters a filtered collection' do
      expect(File.read('output/index.html')).to eq('')

      File.write('content/nanoc.md', "---\ntitle: Nanoc\nkind: work\n---\n")
      FileUtils.touch('content/nanoc.md', mtime: time + 1)

      Nanoc::CLI.run(['compile'])

      expect(File.read('output/index.html')).to eq('Nanoc')
    end
  end

  context 'only raw content dependency' do
    before do
      File.write('content/foo.md', "---\ntitle: hello\n---\n\nfoo")
      File.write('content/bar.md', '<%= @items["/foo.*"].raw_content %>')

      File.write('Rules', <<~EOS)
        compile '/foo.*' do
          write '/foo.html'
        end

        compile '/bar.*' do
          filter :erb
          write '/bar.html'
        end
      EOS

      Nanoc::CLI.run(['compile'])
    end

    it 'shows default rep outdatedness' do
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is not outdated}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is not outdated}).to_stdout,
      )
    end

    it 'shows file as outdated after modification' do
      File.write('content/bar.md', 'JUST BAR!')

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is not outdated}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout,
      )
    end

    it 'shows file and dependencies as outdated after content modification' do
      File.write('content/foo.md', "---\ntitle: hello\n---\n\nfoooOoooOOoooOooo")

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is outdated:}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout,
      )
    end

    it 'shows file and dependencies as not outdated after title modification' do
      File.write('content/foo.md', "---\ntitle: bye\n---\n\nfoo")

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is outdated:}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is not outdated}).to_stdout,
      )
    end
  end

  context 'attribute and raw content dependency' do
    before do
      File.write('content/foo.md', "---\ntitle: hello\n---\n\nfoo")
      File.write('content/bar.md', '<%= @items["/foo.*"].raw_content %> / <%= @items["/foo.*"][:title] %>')

      File.write('Rules', <<~EOS)
        compile '/foo.*' do
          write '/foo.html'
        end

        compile '/bar.*' do
          filter :erb
          write '/bar.html'
        end
      EOS

      Nanoc::CLI.run(['compile'])
    end

    it 'shows default rep outdatedness' do
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is not outdated}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is not outdated}).to_stdout,
      )
    end

    it 'shows file as outdated after modification' do
      File.write('content/bar.md', 'JUST BAR!')

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is not outdated}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout,
      )
    end

    it 'shows file and dependencies as outdated after content modification' do
      File.write('content/foo.md', "---\ntitle: hello\n---\n\nfoooOoooOOoooOooo")

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is outdated:}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout,
      )
    end

    it 'shows file and dependencies as outdated after title modification' do
      File.write('content/foo.md', "---\ntitle: bye\n---\n\nfoo")

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is outdated:}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is outdated:}).to_stdout,
      )
    end

    it 'shows file and dependencies as not outdated after rule modification' do
      File.write('Rules', <<~EOS)
        compile '/foo.*' do
          filter :erb
          write '/foo.html'
        end

        compile '/bar.*' do
          filter :erb
          write '/bar.html'
        end
      EOS

      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /foo\.md, rep default:\n  is outdated:}).to_stdout,
      )
      expect { Nanoc::CLI.run(['show-data', '--no-color']) }.to(
        output(%r{^item /bar\.md, rep default:\n  is not outdated}).to_stdout,
      )
    end
  end
end
