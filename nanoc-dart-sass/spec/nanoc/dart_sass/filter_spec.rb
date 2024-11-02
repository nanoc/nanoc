# frozen_string_literal: true

describe Nanoc::DartSass::Filter, helper: true do
  it 'supports simple .scss' do
    # Create item
    ctx.create_item('stuff', {}, '/foo.scss')
    ctx.create_rep(ctx.items['/foo.scss'], '/assets/foo.css')
    ctx.item = ctx.items['/foo.scss']

    filter = described_class.new(ctx.assigns)

    res = filter.run(<<~SCSS)
      $primary-color: #333;

      body {
        color: $primary-color;
      }
    SCSS

    expect(res.strip).to match(/color: #333/m)
  end

  it 'supports simple .scss with manual syntax' do
    # Create item
    ctx.create_item('stuff', {}, '/foo.css')
    ctx.create_rep(ctx.items['/foo.css'], '/assets/foo.css')
    ctx.item = ctx.items['/foo.css']

    filter = described_class.new(ctx.assigns)

    res = filter.run(<<~SCSS, syntax: 'scss')
      $primary-color: #333;

      body {
        color: $primary-color;
      }
    SCSS

    expect(res.strip).to match(/color: #333/m)
  end

  it 'supports simple .sass' do
    # Create item
    ctx.create_item('stuff', {}, '/foo.sass')
    ctx.create_rep(ctx.items['/foo.sass'], '/assets/foo.css')
    ctx.item = ctx.items['/foo.sass']

    filter = described_class.new(ctx.assigns)

    res = filter.run(<<~SASS)
      $primary-color: #333

      body
        color: $primary-color
    SASS

    expect(res.strip).to match(/color: #333/m)
  end

  context 'when one item depends on another with absolute path' do
    before do
      # Create item
      ctx.create_item('stuff', {}, '/foo.scss')
      ctx.create_rep(ctx.items['/foo.scss'], '/assets/foo.css')
      ctx.item = ctx.items['/foo.scss']

      # Create other item
      ctx.create_item('$primary-color: #900;', {}, '/defs.scss')
      ctx.create_rep(ctx.items['/defs.scss'], '/assets/defs.css')
    end

    let(:content) do
      <<~SCSS
        @use '/defs.*';

        body {
          color: defs.$primary-color;
        }
      SCSS
    end

    it 'supports reading from dependencies' do
      filter = described_class.new(ctx.assigns)

      res = filter.run(content)
      expect(res.strip).to match(/color: #900/m)
    end

    it 'creates Nanoc dependencies' do
      filter = described_class.new(ctx.assigns)

      expect { filter.run(content) }
        .to create_dependency_from(ctx.items['/foo.scss'])
        .onto([instance_of(Nanoc::Core::ItemCollection), ctx.items['/defs.scss']])
    end
  end

  context 'when one item depends on another with relative path' do
    before do
      # Create item
      ctx.create_item('stuff', {}, '/assets/style/foo.scss')
      ctx.create_rep(ctx.items['/assets/style/foo.scss'], '/assets/foo.css')
      ctx.item = ctx.items['/assets/style/foo.scss']

      # Create other items
      ctx.create_item('$fg-color: #900;', {}, '/assets/style/defs1.scss')
      ctx.create_rep(ctx.items['/assets/style/defs1.scss'], '/assets/defs1.css')
      ctx.create_item('$bg-color: #dff;', {}, '/assets/style/defs2.scss')
      ctx.create_rep(ctx.items['/assets/style/defs2.scss'], '/assets/defs2.css')
      ctx.create_item('$hl: #f00;', {}, '/assets/style/defs3.scss')
      ctx.create_rep(ctx.items['/assets/style/defs3.scss'], '/assets/defs3.css')
    end

    let(:content) do
      <<~SCSS
        @use './defs1.*';
        @use 'defs2.*';
        @use 'defs3';

        body {
          color: defs1.$fg-color;
          background: defs2.$bg-color;
        }
      SCSS
    end

    it 'supports reading from dependencies' do
      filter = described_class.new(ctx.assigns)

      res = filter.run(content)
      expect(res.strip).to match(/color: #900/m)
      expect(res.strip).to match(/background: #dff/m)
    end

    it 'creates Nanoc dependencies' do
      filter = described_class.new(ctx.assigns)

      expect { filter.run(content) }
        .to create_dependency_from(ctx.items['/assets/style/foo.scss'])
        .onto(
          [
            instance_of(Nanoc::Core::ItemCollection),
            ctx.items['/assets/style/defs1.scss'],
            ctx.items['/assets/style/defs2.scss'],
            ctx.items['/assets/style/defs3.scss'],
          ],
        )
    end
  end
end
