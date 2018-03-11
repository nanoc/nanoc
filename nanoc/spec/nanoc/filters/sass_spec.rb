# frozen_string_literal: true

describe Nanoc::Filters::Sass do
  subject(:filter) { ::Nanoc::Filters::Sass.new }

  before { require 'sass' }

  it 'can be called with content' do
    expect(filter.setup_and_run(".foo #bar\n  color: #f00"))
      .to match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}/)
  end

  it 'compacts when using style=compact' do
    expect(filter.setup_and_run(".foo #bar\n  color: #f00", style: 'compact'))
      .to match(/^\.foo #bar[\s]*\{[\s]*color:\s*(red|#f00);?[\s]*\}/m)
  end

  it 'compacts when using style=compressed' do
    expect(filter.setup_and_run(".foo #bar\n  color: #f00", style: 'compressed'))
      .to match(/^\.foo #bar[\s]*\{[\s]*color:\s*(red|#f00);?[\s]*\}/m)
  end

  it 'supports SCSS' do
    expect(filter.setup_and_run(".foo { color: #f00 }", syntax: :scss))
      .to match(/^\.foo[\s]*\{[\s]*color:\s*(red|#f00);?[\s]*\}/m)
  end

  it 'raises proper error on failure' do
    expect { filter.setup_and_run('$*#&!@($') }
      .to raise_error(::Sass::SyntaxError, /Invalid variable/)
  end

  context 'with item, items, config context' do
    subject(:filter) { ::Nanoc::Filters::Sass.new(filter_params) }

    let(:filter_params) do
      {
        item: item_view,
        items: item_views,
        config: config,
      }
    end

    let(:item) do
      Nanoc::Int::Item.new(
        content,
        { content_filename: 'content/style/main.sass' },
        '/style/main.sass',
      )
    end

    let(:content) do
      Nanoc::Int::TextualContent.new(
        '/* irrelevant */',
        filename: File.expand_path('content/style/main.sass'),
      )
    end

    let(:item_view) { Nanoc::CompilationItemView.new(item, view_context) }

    let(:item_views) { [item_view] }

    let(:view_context) do
      Nanoc::ViewContextForCompilation.new(
        reps: reps,
        items: items,
        dependency_tracker: dependency_tracker,
        compilation_context: compilation_context,
        snapshot_repo: snapshot_repo,
      )
    end

    let(:reps) { Nanoc::Int::ItemRepRepo.new }
    let(:items) { Nanoc::Int::ItemCollection.new(config) }
    let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(dependency_store) }
    let(:dependency_store) { Nanoc::Int::DependencyStore.new(empty_items, empty_layouts, config) }
    let(:compilation_context) { double(:compilation_context) }
    let(:snapshot_repo) { Nanoc::Int::SnapshotRepo.new }

    let(:empty_items) { Nanoc::Int::ItemCollection.new(config) }
    let(:empty_layouts) { Nanoc::Int::LayoutCollection.new(config) }

    let(:config) { Nanoc::Int::Configuration.new.with_defaults }

    before do
      FileUtils.mkdir_p(File.dirname(item.attributes[:content_filename]))
      File.write(item.attributes[:content_filename], item.content)
      File.write('content/style/stuff.sass', ".foo #bar\n  color: #f00")
      File.write('content/style/_partial.sass', ".qux\n  color: #00f")
    end

    it 'can import by relative path' do
      expect(filter.setup_and_run('@import stuff'))
        .to match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}/)
    end

    it 'cannot import by nested relative path' do
      expect { filter.setup_and_run('@import content/style/stuff') }
        .to raise_error(::Sass::SyntaxError, /File to import not found/)
    end

    it 'can import by relative path with extension' do
      expect(filter.setup_and_run('@import stuff.sass'))
        .to match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}/)
    end

    it 'cannot import by nested relative path with extension' do
      expect { filter.setup_and_run('@import content/style/stuff.sass') }
        .to raise_error(::Sass::SyntaxError, /File to import not found/)
    end

    it 'can import partials by relative path' do
      expect(filter.setup_and_run('@import partial'))
        .to match(/.qux\s*\{\s*color:\s+(blue|#00f);?\s*\}/)
    end

    it 'cannot import partials by nested relative path' do
      expect { filter.setup_and_run('@import content/style/partial') }
        .to raise_error(::Sass::SyntaxError, /File to import not found/)
    end

    it 'can import partials by relative path with extension' do
      expect(filter.setup_and_run('@import partial.sass'))
        .to match(/.qux\s*\{\s*color:\s+(blue|#00f);?\s*\}/)
    end

    it 'cannot import partials by nested relative path with extension' do
      expect { filter.setup_and_run('@import content/style/partial.sass') }
        .to raise_error(::Sass::SyntaxError, /File to import not found/)
    end

    context 'importing a file for which an item does not exist' do
      it 'can import' do
        expect(filter.setup_and_run('@import partial.sass'))
          .to match(/.qux\s*\{\s*color:\s+(blue|#00f);?\s*\}/)
      end

      it 'creates no dependency' do
        expect { filter.setup_and_run('@import partial.sass') }
          .not_to create_dependency_from(item_view)
      end
    end

    context 'importing a file for which an item exists' do
      let(:target_item) do
        Nanoc::Int::Item.new(
          content,
          { content_filename: 'content/style/_partial.sass' },
          '/style/_partial.sass',
        )
      end

      let(:content) do
        Nanoc::Int::TextualContent.new(
          '/* irrelevant */',
          filename: File.expand_path('content/style/_partial.sass'),
        )
      end

      let(:target_item_view) { Nanoc::CompilationItemView.new(target_item, view_context) }

      let(:item_views) { [item_view, target_item_view] }

      it 'can import' do
        expect(filter.setup_and_run('@import partial.sass'))
          .to match(/.qux\s*\{\s*color:\s+(blue|#00f);?\s*\}/)
      end

      it 'creates a dependency' do
        expect { filter.setup_and_run('@import partial.sass') }
          .to create_dependency_on(target_item_view)
      end
    end

    context 'load_path set' do
      before do
        FileUtils.mkdir_p('content/xyzzy')
        File.write('content/xyzzy/_hello.sass', ".hello\n  color: #0ff")
      end

      context 'importing a file for which an item does not exist' do
        it 'can import' do
          expect(filter.setup_and_run('@import hello.sass', load_paths: ['content/xyzzy']))
            .to match(/.hello\s*\{\s*color:\s+#0ff;?\s*\}/)
        end

        it 'creates no dependency' do
          expect { filter.setup_and_run('@import hello.sass', load_paths: ['content/xyzzy']) }
            .not_to create_dependency_from(item_view)
        end
      end

      context 'importing a file for which an item exists' do
        let(:target_item) do
          Nanoc::Int::Item.new(
            content,
            { content_filename: 'content/style/_partial.sass' },
            '/style/_partial.sass',
          )
        end

        let(:content) do
          Nanoc::Int::TextualContent.new(
            '/* irrelevant */',
            filename: File.expand_path('content/style/_partial.sass'),
          )
        end

        let(:target_item_view) { Nanoc::CompilationItemView.new(target_item, view_context) }

        let(:item_views) { [item_view, target_item_view] }

        it 'can import' do
          expect(filter.setup_and_run('@import hello.sass', load_paths: ['content/xyzzy']))
            .to match(/.hello\s*\{\s*color:\s+#0ff;?\s*\}/)
        end

        it 'creates a dependency' do
          expect { filter.setup_and_run('@import hello.sass', load_paths: ['content/xyzzy']) }
            .to create_dependency_on(target_item_view)
        end
      end
    end
  end
end
