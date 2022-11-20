# frozen_string_literal: true

describe Nanoc::DartSass::Filter, helper: true do
  it 'supports simple .scss' do
    # Create item
    ctx.create_item('stuff', {}, '/foo.scss')
    ctx.create_rep(ctx.items['/foo.scss'], '/assets/foo.css')
    ctx.item = ctx.items['/foo.scss']

    filter = ::Nanoc::DartSass::Filter.new(ctx.assigns)

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

    filter = ::Nanoc::DartSass::Filter.new(ctx.assigns)

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

    filter = ::Nanoc::DartSass::Filter.new(ctx.assigns)

    res = filter.run(<<~SASS)
      $primary-color: #333

      body
        color: $primary-color
    SASS

    expect(res.strip).to match(/color: #333/m)
  end

  context 'when one item depends on another' do
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
        @import '/defs.*';

        body {
          color: $primary-color;
        }
      SCSS
    end

    it 'supports reading from dependencies' do
      filter = ::Nanoc::DartSass::Filter.new(ctx.assigns)

      res = filter.run(content)
      expect(res.strip).to match(/color: #900/m)
    end

    it 'creates Nanoc dependencies' do
      filter = ::Nanoc::DartSass::Filter.new(ctx.assigns)

      expect { filter.run(content) }
        .to create_dependency_from(ctx.items['/foo.scss'])
        .onto([instance_of(Nanoc::Core::ItemCollection), ctx.items['/defs.scss']])
    end
  end
end
