# frozen_string_literal: true

describe Nanoc::Int::Errors::DependencyCycle do
  subject(:error) { described_class.new(stack) }

  let(:stack) do
    [
      rep_a,
      rep_b,
      rep_c,
      rep_d,
      rep_e,
      rep_b,
    ]
  end

  let(:rep_a) { Nanoc::Int::ItemRep.new(Nanoc::Int::Item.new('a', {}, '/a.md'), :default) }
  let(:rep_b) { Nanoc::Int::ItemRep.new(Nanoc::Int::Item.new('b', {}, '/b.md'), :default) }
  let(:rep_c) { Nanoc::Int::ItemRep.new(Nanoc::Int::Item.new('c', {}, '/c.md'), :default) }
  let(:rep_d) { Nanoc::Int::ItemRep.new(Nanoc::Int::Item.new('d', {}, '/d.md'), :default) }
  let(:rep_e) { Nanoc::Int::ItemRep.new(Nanoc::Int::Item.new('e', {}, '/e.md'), :default) }

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
