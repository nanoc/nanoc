# frozen_string_literal: true

describe Nanoc::Filters::SassCommon do
  context 'with item, items, config context' do
    subject(:sass) { ::Nanoc::Filter.named(:sass).new(sass_params) }
    subject(:sass_sourcemap) { ::Nanoc::Filter.named(:sass_sourcemap).new(sass_sourcemap_params) }

    let(:sass_params) do
      {
        item: item_main_view,
        item_rep: item_main_default_rep_view,
        items: item_views,
        config: config,
      }
    end

    let(:sass_sourcemap_params) do
      {
        item: item_main_view,
        item_rep: item_main_sourcemap_rep_view,
        items: item_views,
        config: config,
      }
    end

    let(:item_main) do
      Nanoc::Int::Item.new(
        content_main,
        { content_filename: 'content/style/main.sass' },
        '/style/main.sass',
      )
    end

    let(:content_main) do
      Nanoc::Int::TextualContent.new(
        '/* irrelevant */',
        filename: File.expand_path('content/style/main.sass'),
      )
    end

    let(:item_blue) do
      Nanoc::Int::Item.new(
        content_blue,
        { content_filename: 'content/style/colors/blue.sass' },
        '/style/colors/blue.sass',
      )
    end

    let(:content_blue) do
      Nanoc::Int::TextualContent.new(
        "\.blue\n  color: blue",
        filename: File.expand_path('content/style/colors/blue.sass'),
      )
    end

    let(:item_red) do
      Nanoc::Int::Item.new(
        content_red,
        { content_filename: 'content/style/colors/red.scss' },
        '/style/colors/red.scss',
      )
    end

    let(:content_red) do
      Nanoc::Int::TextualContent.new(
        '.red { color: red; }',
        filename: File.expand_path('content/style/colors/red.scss'),
      )
    end

    let(:item_partial) do
      Nanoc::Int::Item.new(
        content_partial,
        { content_filename: 'content/style/_partial.scss' },
        '/style/_partial.scss',
      )
    end

    let(:content_partial) do
      Nanoc::Int::TextualContent.new(
        '* { margin: 0; }',
        filename: File.expand_path('content/style/_partial.scss'),
      )
    end

    let(:item_main_default_rep) do
      Nanoc::Int::ItemRep.new(item_main, :default).tap do |rep|
        rep.raw_paths = rep.paths = { last: [Dir.getwd + '/output/style/main.sass'] }
      end
    end
    let(:item_main_sourcemap_rep) do
      Nanoc::Int::ItemRep.new(item_main, :sourcemap).tap do |rep|
        rep.raw_paths = rep.paths = { last: [Dir.getwd + '/output/style/main.sass.map'] }
      end
    end
    let(:item_main_view) { Nanoc::CompilationItemView.new(item_main, view_context) }
    let(:item_main_default_rep_view) { Nanoc::CompilationItemRepView.new(item_main_default_rep, view_context) }
    let(:item_main_sourcemap_rep_view) { Nanoc::CompilationItemRepView.new(item_main_sourcemap_rep, view_context) }

    let(:items) { Nanoc::Int::ItemCollection.new(config, [item_main, item_blue, item_red, item_partial]) }
    let(:item_views) { Nanoc::ItemCollectionWithRepsView.new(items, view_context) }

    let(:view_context) do
      Nanoc::ViewContextForCompilation.new(
        reps: reps,
        items: items,
        dependency_tracker: dependency_tracker,
        compilation_context: compilation_context,
        snapshot_repo: snapshot_repo,
      )
    end

    let(:reps) do
      Nanoc::Int::ItemRepRepo.new.tap do |reps|
        [item_blue, item_red, item_partial].each do |item|
          reps << Nanoc::Int::ItemRep.new(item, :default).tap do |rep|
            rep.compiled = true
            rep.snapshot_defs = [Nanoc::Int::SnapshotDef.new(:last, binary: false)]
          end
        end
        reps << item_main_default_rep
        reps << item_main_sourcemap_rep
      end
    end
    let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(dependency_store) }
    let(:dependency_store) { Nanoc::Int::DependencyStore.new(empty_items, empty_layouts, config) }
    let(:compilation_context) { double(:compilation_context) }
    let(:snapshot_repo) do
      Nanoc::Int::SnapshotRepo.new.tap do |repo|
        repo.set(reps[item_blue].first, :last, Nanoc::Int::TextualContent.new('.blue { color: blue }'))
        repo.set(reps[item_red].first, :last, Nanoc::Int::TextualContent.new('.red { color: red }'))
        repo.set(reps[item_partial].first, :last, Nanoc::Int::TextualContent.new('* { margin: 0 }'))
      end
    end

    let(:empty_items) { Nanoc::Int::ItemCollection.new(config) }
    let(:empty_layouts) { Nanoc::Int::LayoutCollection.new(config) }

    let(:config) { Nanoc::Int::Configuration.new(dir: Dir.getwd).with_defaults.merge(color: 'yellow') }

    before do
      items.each do |item|
        FileUtils.mkdir_p(File.dirname(item.attributes[:content_filename]))
        File.write(item.attributes[:content_filename], item.content)
      end
    end

    it 'can be called with content' do
      expect(sass.setup_and_run(".foo #bar\n  color: #f00"))
        .to match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}/)
    end

    it 'compacts when using style=compact' do
      expect(sass.setup_and_run(".foo #bar\n  color: #f00", style: 'compact'))
        .to match(/^\.foo #bar[\s]*\{[\s]*color:\s*(red|#f00);?[\s]*\}/m)
    end

    it 'compacts when using style=compressed' do
      expect(sass.setup_and_run(".foo #bar\n  color: #f00", style: 'compressed'))
        .to match(/^\.foo #bar[\s]*\{[\s]*color:\s*(red|#f00);?[\s]*\}/m)
    end

    it 'supports SCSS' do
      expect(sass.setup_and_run('.foo { color: #f00 }', syntax: :scss))
        .to match(/^\.foo[\s]*\{[\s]*color:\s*(red|#f00);?[\s]*\}/m)
    end

    it 'raises proper error on failure' do
      expect { sass.setup_and_run('$*#&!@($') }
        .to raise_error(::Sass::SyntaxError, /Invalid variable/)
    end

    context 'importing a file for which an item exists' do
      it 'can import by relative path' do
        expect(sass.setup_and_run('@import colors/blue'))
          .to match(/\A\.blue\s+\{\s*color:\s+blue;?\s*\}\s*\z/)
        expect(sass.setup_and_run('@import colors/red'))
          .to match(/\A\.red\s+\{\s*color:\s+red;?\s*\}\s*\z/)
      end

      it 'cannot import by nested relative path' do
        expect { sass.setup_and_run('@import content/style/colors/blue') }
          .to raise_error(::Sass::SyntaxError, /File to import not found/)
        expect { sass.setup_and_run('@import content/style/colors/red') }
          .to raise_error(::Sass::SyntaxError, /File to import not found/)
      end

      it 'can import by relative path with extension' do
        expect(sass.setup_and_run('@import colors/blue.sass'))
          .to match(/\A\.blue\s+\{\s*color:\s+blue;?\s*\}\s*\z/)
        expect(sass.setup_and_run('@import colors/red.scss'))
          .to match(/\A\.red\s+\{\s*color:\s+red;?\s*\}\s*\z/)
      end

      it 'cannot import by nested relative path with extension' do
        expect { sass.setup_and_run('@import content/style/colors/blue.sass') }
          .to raise_error(::Sass::SyntaxError, /File to import not found/)
        expect { sass.setup_and_run('@import content/style/colors/red.scss') }
          .to raise_error(::Sass::SyntaxError, /File to import not found/)
      end

      it 'can import partials by relative path' do
        expect(sass.setup_and_run('@import partial'))
          .to match(/\A\*\s*\{\s*margin:\s+0;\s*\}\s*\z/)
      end

      it 'cannot import partials by nested relative path' do
        expect { sass.setup_and_run('@import content/style/_partial') }
          .to raise_error(::Sass::SyntaxError, /File to import not found/)
      end

      it 'can import partials by relative path with extension' do
        expect(sass.setup_and_run('@import partial.scss'))
          .to match(/\A\*\s*\{\s*margin:\s+0;\s*\}\s*\z/)
      end

      it 'cannot import partials by nested relative path with extension' do
        expect { sass.setup_and_run('@import content/style/partial.scss') }
          .to raise_error(::Sass::SyntaxError, /File to import not found/)
      end

      it 'creates a dependency' do
        expect { sass.setup_and_run('@import partial') }
          .to create_dependency_on(item_views[item_partial.identifier])
      end
    end

    context 'importing a file for which an item does not exist' do
      before { File.write('_external.scss', 'body { font: 100%; }') }

      context 'load_path set' do
        it 'can import by relative path' do
          expect(sass.setup_and_run('@import external', load_paths: ['.']))
            .to match(/\Abody\s+\{\s*font:\s+100%;?\s*\}\s*\z/)
        end

        it 'creates no dependency' do
          expect { sass.setup_and_run('@import external', load_paths: ['.']) }
            .to create_dependency_from(item_main_view).onto([instance_of(Nanoc::Int::ItemCollection)])
        end
      end

      context 'load_path not set' do
        it 'cannot import by relative path' do
          expect { sass.setup_and_run('@import external') }
            .to raise_error(::Sass::SyntaxError, /File to import not found/)
        end
      end
    end

    context 'importing by identifier or pattern' do
      it 'can import by identifier' do
        expect(sass.setup_and_run('@import /style/colors/blue.*'))
          .to match(/\A\.blue\s+\{\s*color:\s+blue;?\s*\}\s*\z/)
        expect(sass.setup_and_run('@import /style/colors/red.*'))
          .to match(/\A\.red\s+\{\s*color:\s+red;?\s*\}\s*\z/)
      end

      it 'can import by pattern' do
        expect(sass.setup_and_run('@import /style/colors/*'))
          .to match(/\A\.blue\s+\{\s*color:\s+blue;?\s*\}\s*\.red\s+\{\s*color:\s+red;?\s*\}\s*\z/)
      end
    end

    context 'sourcemaps' do
      it 'generates proper sourcemaps' do
        expect(sass.setup_and_run(".foo #bar\n  color: #f00", sourcemap_path: 'main.sass.map'))
          .to match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}\s*\/\*# sourceMappingURL=main.sass.map \*\//)

        expect(sass_sourcemap.setup_and_run(".foo #bar\n  color: #f00", sourcemap_path: 'main.sass.map'))
          .to match(/{.*?"sources": \["#{item_main_default_rep.raw_path}"\].*?"file": "#{item_main_sourcemap_rep.raw_path}".*?}/m)
      end
    end

    context 'nanoc() sass function' do
      it 'can inspect @config' do
        expect(sass.setup_and_run(".foo #bar\n  color: nanoc('@config[:color]', $unquote: true)"))
          .to match(/.foo\s+#bar\s*\{\s*color:\s+yellow;?\s*\}/)
      end

      it 'can inspect @items' do
        expect(sass.setup_and_run(".foo\n  content: nanoc('@items[\"/style/main.*\"][:content_filename]')"))
          .to match(/.foo\s*\{\s*content:\s+"content\/style\/main\.sass";?\s*\}/)
      end
    end
  end
end
