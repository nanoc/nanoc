# frozen_string_literal: true

describe Nanoc::Core::Errors::DependencyCycle do
  subject(:error) { described_class.new(cycle) }

  let(:cycle) do
    [
      rep_b,
      rep_c,
      rep_d,
      rep_e,
    ]
  end

  let(:rep_a) { Nanoc::Core::ItemRep.new(Nanoc::Core::Item.new('a', {}, '/a.md'), :default) }
  let(:rep_b) { Nanoc::Core::ItemRep.new(Nanoc::Core::Item.new('b', {}, '/b.md'), :default) }
  let(:rep_c) { Nanoc::Core::ItemRep.new(Nanoc::Core::Item.new('c', {}, '/c.md'), :default) }
  let(:rep_d) { Nanoc::Core::ItemRep.new(Nanoc::Core::Item.new('d', {}, '/d.md'), :default) }
  let(:rep_e) { Nanoc::Core::ItemRep.new(Nanoc::Core::Item.new('e', {}, '/e.md'), :default) }

  it 'has an informative error message' do
    expected = <<~EOS
      The site cannot be compiled because there is a dependency cycle:

          (1) item /b.md, rep :default, uses compiled content of
          (2) item /c.md, rep :default, uses compiled content of
          (3) item /d.md, rep :default, uses compiled content of
          (4) item /e.md, rep :default, uses compiled content of (1)
    EOS

    expect(error.message).to eql(expected)
  end
end
