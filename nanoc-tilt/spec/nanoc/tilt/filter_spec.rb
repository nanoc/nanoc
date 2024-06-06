# frozen_string_literal: true

describe Nanoc::Tilt::Filter do
  it 'supports .erb' do
    item = Nanoc::Core::Item.new('stuff', {}, '/foo.erb')
    item_rep = Nanoc::Core::ItemRep.new(item, :default)

    filter = described_class.new({ item:, item_rep: })

    res = filter.run('<%= "a" * 3 %>')
    expect(res.strip).to eq('aaa')
  end

  it 'supports .erb with options' do
    item = Nanoc::Core::Item.new('stuff', {}, '/foo.erb')
    item_rep = Nanoc::Core::ItemRep.new(item, :default)

    filter = described_class.new({ item:, item_rep: })

    res = filter.run('<%= "&" * 3 %>', args: { escape: false })
    expect(res.strip).to eq('&&&')

    res = filter.run('<%= "&" * 3 %>', args: { escape: true })
    expect(res.strip).to eq('&amp;&amp;&amp;')
  end
end
