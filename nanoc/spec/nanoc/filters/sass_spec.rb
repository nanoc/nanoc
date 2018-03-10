# frozen_string_literal: true

describe Nanoc::Filters::Sass do
  subject(:filter) { ::Nanoc::Filters::Sass.new }

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

  it 'raises proper error on failure' do
    expect { filter.setup_and_run('$*#&!@($') }
      .to raise_error(Sass::SyntaxError, /Invalid variable/)
  end

  context 'with item, items, config context' do
    subject(:filter) { ::Nanoc::Filters::Sass.new(filter_params) }

    let(:filter_params) do
      {
        item: item_view,
        items: item_views,
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

    let(:item_view) { Nanoc::CompilationItemView.new(item, nil) }

    let(:item_views) { [item_view] }

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
        .to raise_error(Sass::SyntaxError, /File to import not found/)
    end

    it 'can import by relative path with extension' do
      expect(filter.setup_and_run('@import stuff.sass'))
        .to match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}/)
    end

    it 'cannot import by nested relative path with extension' do
      expect { filter.setup_and_run('@import content/style/stuff.sass') }
        .to raise_error(Sass::SyntaxError, /File to import not found/)
    end

    it 'can import partials by relative path' do
      expect(filter.setup_and_run('@import partial'))
        .to match(/.qux\s*\{\s*color:\s+(blue|#00f);?\s*\}/)
    end

    it 'cannot import partials by nested relative path' do
      expect { filter.setup_and_run('@import content/style/partial') }
        .to raise_error(Sass::SyntaxError, /File to import not found/)
    end

    it 'can import partials by relative path with extension' do
      expect(filter.setup_and_run('@import partial.sass'))
        .to match(/.qux\s*\{\s*color:\s+(blue|#00f);?\s*\}/)
    end

    it 'cannot import partials by nested relative path with extension' do
      expect { filter.setup_and_run('@import content/style/partial.sass') }
        .to raise_error(Sass::SyntaxError, /File to import not found/)
    end
  end

  # TODO: test :load_paths
  # TODO: test scss
end
