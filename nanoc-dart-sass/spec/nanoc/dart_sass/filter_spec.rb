# frozen_string_literal: true

describe Nanoc::DartSass::Filter, :helper do
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

  it 'supports source_map' do
    # Create item
    ctx.create_item('stuff', {}, '/foo.sass')
    ctx.create_rep(ctx.items['/foo.sass'], '/assets/foo.css')
    ctx.item = ctx.items['/foo.sass']

    filter = described_class.new(ctx.assigns)

    res = filter.run(<<~SASS, source_map: true)
      $primary-color: #333

      body
        color: $primary-color
    SASS

    expect(res.strip).to match(/sourceMappingURL/m)
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

    it 'creates dependencies' do
      filter = described_class.new(ctx.assigns)

      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items._unwrap, { raw_content: ['/_defs.sass'] })
      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items._unwrap, { raw_content: ['/_defs.scss'] })
      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items._unwrap, { raw_content: ['/_defs.*.sass'] })
      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items._unwrap, { raw_content: ['/_defs.*.scss'] })
      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items._unwrap, { raw_content: ['/_defs.*.css'] })
      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items._unwrap, { raw_content: ['/defs.sass'] })
      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items._unwrap, { raw_content: ['/defs.scss'] })
      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items._unwrap, { raw_content: ['/defs.*.sass'] })
      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items._unwrap, { raw_content: ['/defs.*.scss'] })
      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items._unwrap, { raw_content: ['/defs.*.css'] })

      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items['/defs.scss']._unwrap, raw_content: true)

      filter.run(content)
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

    it 'creates dependencies' do
      filter = described_class.new(ctx.assigns)

      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items._unwrap, anything).at_least(:once)

      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items['/assets/style/defs1.scss']._unwrap, raw_content: true)
      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items['/assets/style/defs2.scss']._unwrap, raw_content: true)
      expect(ctx.dependency_tracker).to receive(:bounce).with(ctx.items['/assets/style/defs3.scss']._unwrap, raw_content: true)

      filter.run(content)
    end
  end
end
