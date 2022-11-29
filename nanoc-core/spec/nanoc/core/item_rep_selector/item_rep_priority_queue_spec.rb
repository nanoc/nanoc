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

      expect(micro_graph.next).to be_nil
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

      expect(micro_graph.next).to be_nil
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

      expect(micro_graph.next).to be_nil
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

  context 'when there are two regular dependencies' do
    it 'schedules the dependency next up' do
      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_failed(reps[2])

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_failed(reps[4])

      expect(micro_graph.next).to eq(reps[4])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[3])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_ok

      expect(micro_graph.next).to be_nil
    end
  end

  context 'when there is one regular dependency and one cyclical dependency' do
    it 'schedules the dependency next up' do
      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_failed(reps[2])

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_failed(reps[4])

      expect(micro_graph.next).to eq(reps[4])
      expect { micro_graph.mark_failed(reps[1]) }
        .to raise_error(Nanoc::Core::Errors::DependencyCycle)
    end
  end

  context 'when there is a transitive dependency' do
    it 'schedules the dependency next up' do
      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_failed(reps[1])

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_failed(reps[2])

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_failed(reps[3])

      expect(micro_graph.next).to eq(reps[3])
      micro_graph.mark_failed(reps[4])

      expect(micro_graph.next).to eq(reps[4])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[3])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_ok

      expect(micro_graph.next).to be_nil
    end
  end

  context 'when there is an item with dependencies on many other items that also have dependences' do
    # 0 -> 2
    # 2 -> 4
    # 4 OK
    # 1 -> 2
    # 2 -> 3
    # 3 OK
    it 'schedules the dependency next up' do
      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_failed(reps[2])

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_failed(reps[4])

      expect(micro_graph.next).to eq(reps[4])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_failed(reps[2])

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_failed(reps[3])

      expect(micro_graph.next).to eq(reps[3])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_ok

      expect(micro_graph.next).to be_nil
    end
  end

  context 'when there is an item with dependencies on an item that was delayed due to another dependency' do
    # 0 -> 3
    # 3 OK
    # 1 -> 0
    # 0 OK
    it 'schedules the dependency next up' do
      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_failed(reps[3])

      expect(micro_graph.next).to eq(reps[3])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_failed(reps[0])

      expect(micro_graph.next).to eq(reps[0])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[2])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[4])
      micro_graph.mark_ok

      expect(micro_graph.next).to eq(reps[1])
      micro_graph.mark_ok

      expect(micro_graph.next).to be_nil
    end
  end
end
