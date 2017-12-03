# frozen_string_literal: true

describe Nanoc::Spec::HelperContext do
  let(:helper) do
    Module.new {}
  end

  subject(:ctx) { described_class.new(helper) }

  it 'has no items by default' do
    # TODO: Add #empty? to item collection view
    expect(subject.items.size).to eq(0)
  end

  it 'has no layouts by default' do
    # TODO: Add #empty? to item collection view
    expect(subject.layouts.size).to eq(0)
  end

  describe '#create_item' do
    subject { ctx.create_item('foo', {}, '/foo.md') }

    it 'creates item' do
      expect { subject }
        .to change { ctx.items.size }
        .from(0).to(1)
    end

    it 'creates item without reps' do
      subject
      expect(ctx.items['/foo.md'].reps.size).to eq(0)
    end

    it 'returns self' do
      expect(subject).to eq(ctx)
    end
  end

  describe '#create_layout' do
    subject { ctx.create_layout('foo', {}, '/foo.md') }

    it 'creates layout' do
      expect { subject }
        .to change { ctx.layouts.size }
        .from(0).to(1)
    end

    it 'returns self' do
      expect(subject).to eq(ctx)
    end
  end

  describe '#create_rep' do
    before do
      ctx.create_item('foo', {}, '/foo.md')
    end

    subject { ctx.create_rep(ctx.items['/foo.md'], '/foo.html') }

    it 'creates rep' do
      expect { subject }
        .to change { ctx.items['/foo.md'].reps.size }
        .from(0).to(1)
    end

    it 'returns self' do
      expect(subject).to eq(ctx)
    end
  end
end
