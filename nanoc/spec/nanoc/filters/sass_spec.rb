# frozen_string_literal: true

describe Nanoc::Filters::SassCommon do
  context 'with item, items, config context' do
    subject(:sass_sourcemap) do
      Nanoc::Filter.named(:sass_sourcemap).new(sass_sourcemap_params)
    end

    let(:sass) { Nanoc::Filter.named(:sass).new(sass_params) }

    let(:sass_params) do
      {
        item: item_main_view,
        item_rep: item_main_default_rep_view,
        items: item_views,
        config:,
      }
    end

    let(:sass_sourcemap_params) do
      {
        item: item_main_view,
        item_rep: item_main_sourcemap_rep_view,
        items: item_views,
        config:,
      }
    end

    let(:item_main) do
      Nanoc::Core::Item.new(
        content_main,
        { content_filename: 'content/style/main.sass' },
        '/style/main.sass',
      )
    end

    let(:content_main) do
      Nanoc::Core::TextualContent.new(
        '/* irrelevant */',
        filename: File.expand_path('content/style/main.sass'),
      )
    end

    let(:item_blue) do
      Nanoc::Core::Item.new(
        content_blue,
        { content_filename: 'content/style/colors/blue.sass' },
        '/style/colors/blue.sass',
      )
    end

    let(:content_blue) do
      Nanoc::Core::TextualContent.new(
        ".blue\n  color: blue",
        filename: File.expand_path('content/style/colors/blue.sass'),
      )
    end

    let(:item_red) do
      Nanoc::Core::Item.new(
        content_red,
        { content_filename: 'content/style/colors/red.scss' },
        '/style/colors/red.scss',
      )
    end

    let(:content_red) do
      Nanoc::Core::TextualContent.new(
        '.red { color: red; }',
        filename: File.expand_path('content/style/colors/red.scss'),
      )
    end

    let(:item_partial_scss) do
      Nanoc::Core::Item.new(
        content_partial_scss,
        { content_filename: 'content/style/_partial.scss' },
        '/style/_partial.scss',
      )
    end

    let(:content_partial_scss) do
      Nanoc::Core::TextualContent.new(
        '* { margin: 0; }',
        filename: File.expand_path('content/style/_partial.scss'),
      )
    end

    let(:item_partial_sass) do
      Nanoc::Core::Item.new(
        content_partial_sass,
        { content_filename: 'content/style/_sass-partial.sass' },
        '/style/_sass-partial.sass',
      )
    end

    let(:content_partial_sass) do
      sass = <<~SASS
        *
          margin: 0
      SASS

      Nanoc::Core::TextualContent.new(
        sass,
        filename: File.expand_path('content/style/_sass-partial.sass'),
      )
    end

    let(:item_partial_sass_anonymous) do
      Nanoc::Core::Item.new(
        content_partial_sass_anonymous,
        { content_filename: 'content/style/_anonymous-sass-partial' },
        '/style/_anonymous-sass-partial',
      )
    end

    let(:content_partial_sass_anonymous) do
      sass = <<~SASS
        *
          margin: 0
      SASS

      Nanoc::Core::TextualContent.new(
        sass,
        filename: File.expand_path('content/style/_anonymous-sass-partial'),
      )
    end

    let(:item_main_default_rep) do
      Nanoc::Core::ItemRep.new(item_main, :default).tap do |rep|
        rep.raw_paths = rep.paths = { last: [Dir.getwd + '/output/style/main.sass'] }
      end
    end

    let(:item_main_sourcemap_rep) do
      Nanoc::Core::ItemRep.new(item_main, :sourcemap).tap do |rep|
        rep.raw_paths = rep.paths = { last: [Dir.getwd + '/output/style/main.sass.map'] }
      end
    end

    let(:item_main_view) { Nanoc::Core::CompilationItemView.new(item_main, view_context) }
    let(:item_main_default_rep_view) { Nanoc::Core::CompilationItemRepView.new(item_main_default_rep, view_context) }
    let(:item_main_sourcemap_rep_view) { Nanoc::Core::CompilationItemRepView.new(item_main_sourcemap_rep, view_context) }

    let(:items) { Nanoc::Core::ItemCollection.new(config, [item_main, item_blue, item_red, item_partial_scss, item_partial_sass, item_partial_sass_anonymous]) }
    let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }
    let(:item_views) { Nanoc::Core::ItemCollectionWithRepsView.new(items, view_context) }

    let(:view_context) do
      Nanoc::Core::ViewContextForCompilation.new(
        reps:,
        items:,
        dependency_tracker:,
        compilation_context:,
        compiled_content_store:,
      )
    end

    let(:reps) do
      Nanoc::Core::ItemRepRepo.new.tap do |reps|
        [item_blue, item_red, item_partial_scss, item_partial_sass, item_partial_sass_anonymous].each do |item|
          reps << Nanoc::Core::ItemRep.new(item, :default).tap do |rep|
            rep.compiled = true
            rep.snapshot_defs = [Nanoc::Core::SnapshotDef.new(:last, binary: false)]
          end
        end
        reps << item_main_default_rep
        reps << item_main_sourcemap_rep
      end
    end

    let(:dependency_tracker) { Nanoc::Core::DependencyTracker.new(dependency_store) }
    let(:dependency_store) { Nanoc::Core::DependencyStore.new(empty_items, empty_layouts, config) }

    let(:compilation_context) do
      Nanoc::Core::CompilationContext.new(
        action_provider:,
        reps:,
        site:,
        compiled_content_cache:,
        compiled_content_store:,
      )
    end

    let(:action_provider) do
      Class.new(Nanoc::Core::ActionProvider) do
        def self.for(_context)
          raise NotImplementedError
        end

        def initialize; end
      end.new
    end

    let(:compiled_content_cache) { Nanoc::Core::CompiledContentCache.new(config:) }

    let(:compiled_content_store) do
      Nanoc::Core::CompiledContentStore.new.tap do |repo|
        repo.set(reps[item_blue].first, :last, content_blue)
        repo.set(reps[item_red].first, :last, content_red)
        repo.set(reps[item_partial_scss].first, :last, content_partial_scss)
        repo.set(reps[item_partial_sass].first, :last, content_partial_sass)
        repo.set(reps[item_partial_sass_anonymous].first, :last, content_partial_sass_anonymous)
      end
    end

    let(:site) do
      Nanoc::Core::Site.new(
        config:,
        code_snippets: [],
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )
    end

    let(:empty_items) { Nanoc::Core::ItemCollection.new(config) }
    let(:empty_layouts) { Nanoc::Core::LayoutCollection.new(config) }

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults.merge(color: 'yellow') }

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
        .to match(/^\.foo #bar\s*\{\s*color:\s*(red|#f00);?\s*\}/m)
    end

    it 'compacts when using style=compressed' do
      expect(sass.setup_and_run(".foo #bar\n  color: #f00", style: 'compressed'))
        .to match(/^\.foo #bar\s*\{\s*color:\s*(red|#f00);?\s*\}/m)
    end

    it 'supports SASS' do
      content = <<~SASS
        .foo
          color: #f00
      SASS

      expect(sass.setup_and_run(content, syntax: :sass))
        .to match(/^\.foo\s*\{\s*color:\s*(red|#f00);?\s*\}/m)
    end

    it 'supports SASS as default syntax' do
      content = <<~SASS
        .foo
          color: #f00
      SASS

      expect(sass.setup_and_run(content))
        .to match(/^\.foo\s*\{\s*color:\s*(red|#f00);?\s*\}/m)
    end

    it 'supports SCSS' do
      expect(sass.setup_and_run('.foo { color: #f00 }', syntax: :scss))
        .to match(/^\.foo\s*\{\s*color:\s*(red|#f00);?\s*\}/m)
    end

    it 'raises proper error on failure' do
      expect { sass.setup_and_run('$*#&!@($') }
        .to raise_error(Sass::SyntaxError, /Invalid variable/)
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
          .to raise_error(Sass::SyntaxError, /File to import not found/)
        expect { sass.setup_and_run('@import content/style/colors/red') }
          .to raise_error(Sass::SyntaxError, /File to import not found/)
      end

      it 'can import by relative path with extension' do
        expect(sass.setup_and_run('@import colors/blue.sass'))
          .to match(/\A\.blue\s+\{\s*color:\s+blue;?\s*\}\s*\z/)
        expect(sass.setup_and_run('@import colors/red.scss'))
          .to match(/\A\.red\s+\{\s*color:\s+red;?\s*\}\s*\z/)
      end

      it 'cannot import by nested relative path with extension' do
        expect { sass.setup_and_run('@import content/style/colors/blue.sass') }
          .to raise_error(Sass::SyntaxError, /File to import not found/)
        expect { sass.setup_and_run('@import content/style/colors/red.scss') }
          .to raise_error(Sass::SyntaxError, /File to import not found/)
      end

      it 'can import SCSS partials by relative path' do
        expect(sass.setup_and_run('@import partial'))
          .to match(/\A\*\s*\{\s*margin:\s+0;\s*\}\s*\z/)
      end

      it 'can import SASS partials by relative path' do
        expect(sass.setup_and_run('@import sass-partial'))
          .to match(/\A\*\s*\{\s*margin:\s+0;\s*\}\s*\z/)
      end

      it 'cannot import anonymous SASS partials by relative path' do
        expect { sass.setup_and_run('@import anonymous-sass-partial') }
          .to raise_error(Sass::SyntaxError, /File to import not found/)
      end

      it 'cannot import partials by nested relative path' do
        expect { sass.setup_and_run('@import content/style/_partial') }
          .to raise_error(Sass::SyntaxError, /File to import not found/)
      end

      it 'can import partials by relative path with SCSS extension' do
        expect(sass.setup_and_run('@import partial.scss'))
          .to match(/\A\*\s*\{\s*margin:\s+0;\s*\}\s*\z/)
      end

      it 'can import partials by relative path with SASS extension' do
        expect(sass.setup_and_run('@import sass-partial.sass'))
          .to match(/\A\*\s*\{\s*margin:\s+0;\s*\}\s*\z/)
      end

      it 'cannot import partials by relative path without extension' do
        expect { sass.setup_and_run('@import anonymous-sass-partial') }
          .to raise_error(Sass::SyntaxError, /File to import not found/)
      end

      it 'cannot import partials by nested relative path with SCSS extension' do
        expect { sass.setup_and_run('@import content/style/partial.scss') }
          .to raise_error(Sass::SyntaxError, /File to import not found/)
      end

      it 'cannot import partials by nested relative path with SASS extension' do
        expect { sass.setup_and_run('@import content/style/sass-partial.sass') }
          .to raise_error(Sass::SyntaxError, /File to import not found/)
      end

      it 'cannot import partials by nested relative path without extension' do
        expect { sass.setup_and_run('@import content/style/anonymous-sass-partial') }
          .to raise_error(Sass::SyntaxError, /File to import not found/)
      end

      it 'creates a dependency' do
        expect { sass.setup_and_run('@import partial') }
          .to create_dependency_on(item_views[item_partial_scss.identifier])
      end
    end

    context 'importing a file for which an item does not exist' do
      before { File.write('_external.scss', 'body { font: 100%; }') }

      context 'load_path set' do
        it 'can import (using load paths) by relative path' do
          expect(sass.setup_and_run('@import external', load_paths: ['.']))
            .to match(/\Abody\s+\{\s*font:\s+100%;?\s*\}\s*\z/)
        end

        it 'creates no dependency' do
          expect { sass.setup_and_run('@import external', load_paths: ['.']) }
            .to create_dependency_from(item_main_view).onto([instance_of(Nanoc::Core::ItemCollection)])
        end
      end

      context 'load_path not set' do
        it 'cannot import (using load paths) by relative path' do
          expect { sass.setup_and_run('@import external') }
            .to raise_error(Sass::SyntaxError, /File to import not found/)
        end

        it 'can import (using importer) by relative path' do
          expect(sass.setup_and_run('@import "../../_external"'))
            .to match(/\Abody\s+\{\s*font:\s+100%;?\s*\}\s*\z/)
        end
      end
    end

    context 'importing by identifier or pattern' do
      it 'can import SASS by identifier' do
        expect(sass.setup_and_run('@import /style/colors/blue.sass'))
          .to match(/\A\.blue\s+\{\s*color:\s+blue;?\s*\}\s*\z/)
      end

      it 'can import SCSS by identifier' do
        expect(sass.setup_and_run('@import /style/colors/red.scss'))
          .to match(/\A\.red\s+\{\s*color:\s+red;?\s*\}\s*\z/)
      end

      it 'can import SASS by identifier without extension' do
        expect(sass.setup_and_run('@import /style/_anonymous-sass-partial'))
          .to match(/\A\*\s+\{\s*margin:\s+0;?\s*\}\s*\z/)
      end

      it 'can import by pattern' do
        expect(sass.setup_and_run('@import /style/colors/*'))
          .to match(/\A\.blue\s+\{\s*color:\s+blue;?\s*\}\s*\.red\s+\{\s*color:\s+red;?\s*\}\s*\z/)
      end
    end

    context 'sourcemaps' do
      it 'generates proper sourcemaps' do
        expect(sass.setup_and_run(".foo #bar\n  color: #f00", sourcemap_path: 'main.css.map'))
          .to match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}\s*\/\*# sourceMappingURL=main.css.map \*\//)

        expect(sass_sourcemap.setup_and_run(".foo #bar\n  color: #f00", css_path: 'main.css', sourcemap_path: 'main.css.map'))
          .to match(/{.*?"sources": \["#{item_main_default_rep.raw_path}"\].*?"file": "main\.css".*?}/m)

        expect(sass_sourcemap.setup_and_run(".foo #bar\n  color: #f00", sourcemap_path: 'main.css.map'))
          .not_to match(/{.*?"sources": \["#{item_main_default_rep.raw_path}"\].*?"file": ".*?".*?}/m)
      end

      it 'generates inlined sourcemaps' do
        expect(sass.setup_and_run(".foo #bar\n  color: #f00", css_path: 'main.css', sourcemap_path: :inline))
          .to match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}\s*\/\*# sourceMappingURL=data:application\/json;base64.*? \*\//)
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
