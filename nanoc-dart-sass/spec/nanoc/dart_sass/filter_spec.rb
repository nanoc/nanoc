# frozen_string_literal: true

describe Nanoc::DartSass::Filter do
  it 'supports simple .scss' do
    item = Nanoc::Core::Item.new('stuff', {}, '/foo.scss')
    item_rep = Nanoc::Core::ItemRep.new(item, :default)

    filter = ::Nanoc::DartSass::Filter.new({ item: item, item_rep: item_rep })

    res = filter.run(<<~SCSS)
      $primary-color: #333;

      body {
        color: $primary-color;
      }
    SCSS

    expect(res.strip).to match(/color: #333/m)
  end

  it 'supports simple .scss with manual syntax' do
    item = Nanoc::Core::Item.new('stuff', {}, '/foo.css')
    item_rep = Nanoc::Core::ItemRep.new(item, :default)

    filter = ::Nanoc::DartSass::Filter.new({ item: item, item_rep: item_rep })

    res = filter.run(<<~SCSS, syntax: 'scss')
      $primary-color: #333;

      body {
        color: $primary-color;
      }
    SCSS

    expect(res.strip).to match(/color: #333/m)
  end

  it 'supports simple .sass' do
    item = Nanoc::Core::Item.new('stuff', {}, '/foo.sass')
    item_rep = Nanoc::Core::ItemRep.new(item, :default)

    filter = ::Nanoc::DartSass::Filter.new({ item: item, item_rep: item_rep })

    res = filter.run(<<~SCSS)
      $primary-color: #333

      body
        color: $primary-color
    SCSS

    expect(res.strip).to match(/color: #333/m)
  end
end
