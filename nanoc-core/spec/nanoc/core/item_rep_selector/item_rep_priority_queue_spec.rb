# frozen_string_literal: true

describe Nanoc::Core::ItemRepSelector::ItemRepPriorityQueue do
  subject(:micro_graph) { described_class.new(reps) }

  let(:items) do
    [
      Nanoc::Core::Item.new('item A', {}, '/a.md'),
      Nanoc::Core::Item.new('item B', {}, '/b.md'),
      Nanoc::Core::Item.new('item C', {}, '/c.md'),
      Nanoc::Core::Item.new('item D', {}, '/d.md'),
      Nanoc::Core::Item.new('item E', {}, '/e.md'),
    ]
  end

  let(:reps) do
    [
      Nanoc::Core::ItemRep.new(items[0], :default),
      Nanoc::Core::ItemRep.new(items[1], :default),
      Nanoc::Core::ItemRep.new(items[2], :default),
      Nanoc::Core::ItemRep.new(items[3], :default),
      Nanoc::Core::ItemRep.new(items[4], :default),
    ]
  end

  context 'when there are no dependencies' do
    it 'runs through reps in order' do
      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[3])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[4])
      micro_graph.mark_ok
    end
  end

  context 'when is a simple dependency' do
    it 'schedules the dependency next up' do
      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_failed(reps[2])

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[3])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[4])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_ok
    end
  end

  context 'when is a transitive dependency' do
    it 'schedules the dependency next up' do
      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_failed(reps[2])

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_failed(reps[4])

      expect(micro_graph.next).to eq(reps[4])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[3])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_ok
    end
  end

  context 'when is a circular dependency of size 2' do
    it 'schedules the dependency next up' do
      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_failed(reps[2])

      expect(micro_graph.next).to eq(reps[2])
      expect { micro_graph.mark_failed(reps[0]) }
        .to raise_error(Nanoc::Core::Errors::DependencyCycle)
    end
  end

  context 'when is a circular dependency of size 3' do
    it 'schedules the dependency next up' do
      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_failed(reps[2])

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_failed(reps[4])

      expect(micro_graph.next).to eq(reps[4])
      expect { micro_graph.mark_failed(reps[0]) }
        .to raise_error(Nanoc::Core::Errors::DependencyCycle)
    end
  end

  context 'when is a circular dependency of size 4' do
    it 'schedules the dependency next up' do
      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_failed(reps[2])

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_failed(reps[4])

      expect(micro_graph.next).to eq(reps[4])
      micro_graph.mark_failed(reps[3])

      expect(micro_graph.next).to eq(reps[3])
      expect { micro_graph.mark_failed(reps[0]) }
        .to raise_error(Nanoc::Core::Errors::DependencyCycle)
    end
  end
end
