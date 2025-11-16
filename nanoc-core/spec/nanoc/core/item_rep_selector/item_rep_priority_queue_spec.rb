# frozen_string_literal: true

describe Nanoc::Core::ItemRepSelector::ItemRepPriorityQueue do
  subject(:priority_queue) do
    described_class.new(
      outdated_reps:,
      reps: item_rep_repo,
      dependency_store:,
    )
  end

  let(:items) do
    [
      Nanoc::Core::Item.new('item A', {}, '/a.md'),
      Nanoc::Core::Item.new('item B', {}, '/b.md'),
      Nanoc::Core::Item.new('item C', {}, '/c.md'),
      Nanoc::Core::Item.new('item D', {}, '/d.md'),
      Nanoc::Core::Item.new('item E', {}, '/e.md'),
    ]
  end

  let(:outdated_reps) do
    [
      Nanoc::Core::ItemRep.new(items[0], :default),
      Nanoc::Core::ItemRep.new(items[1], :default),
      Nanoc::Core::ItemRep.new(items[2], :default),
      Nanoc::Core::ItemRep.new(items[3], :default),
      Nanoc::Core::ItemRep.new(items[4], :default),
    ]
  end

  let(:item_rep_repo) do
    Nanoc::Core::ItemRepRepo.new.tap do |reps|
      reps.each { reps << _1 }
    end
  end

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:empty_layouts) { Nanoc::Core::LayoutCollection.new(config) }
  let(:empty_items) { Nanoc::Core::ItemCollection.new(config) }

  let(:dependency_store) { Nanoc::Core::DependencyStore.new(empty_items, empty_layouts, config) }

  let(:reps) { outdated_reps }

  context 'when there are no dependencies' do
    it 'runs through reps in order' do
      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[3])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[4])
      priority_queue.mark_ok

      expect(priority_queue.next).to be_nil
    end
  end

  context 'when is a simple dependency' do
    it 'schedules the dependency next up' do
      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_failed(reps[2])

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[3])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[4])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_ok

      expect(priority_queue.next).to be_nil
    end
  end

  context 'when is a transitive dependency' do
    it 'schedules the dependency next up' do
      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_failed(reps[2])

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_failed(reps[4])

      expect(priority_queue.next).to eq(reps[4])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[3])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_ok

      expect(priority_queue.next).to be_nil
    end
  end

  context 'when is a circular dependency of size 2' do
    it 'schedules the dependency next up' do
      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_failed(reps[2])

      expect(priority_queue.next).to eq(reps[2])
      expect { priority_queue.mark_failed(reps[0]) }
        .to raise_error(Nanoc::Core::Errors::DependencyCycle)
    end
  end

  context 'when is a circular dependency of size 3' do
    it 'schedules the dependency next up' do
      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_failed(reps[2])

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_failed(reps[4])

      expect(priority_queue.next).to eq(reps[4])
      expect { priority_queue.mark_failed(reps[0]) }
        .to raise_error(Nanoc::Core::Errors::DependencyCycle)
    end
  end

  context 'when is a circular dependency of size 4' do
    it 'schedules the dependency next up' do
      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_failed(reps[2])

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_failed(reps[4])

      expect(priority_queue.next).to eq(reps[4])
      priority_queue.mark_failed(reps[3])

      expect(priority_queue.next).to eq(reps[3])
      expect { priority_queue.mark_failed(reps[0]) }
        .to raise_error(Nanoc::Core::Errors::DependencyCycle)
    end
  end

  context 'when there are two regular dependencies' do
    it 'schedules the dependency next up' do
      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_failed(reps[2])

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_failed(reps[4])

      expect(priority_queue.next).to eq(reps[4])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[3])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_ok

      expect(priority_queue.next).to be_nil
    end
  end

  context 'when there is one regular dependency and one cyclical dependency' do
    it 'schedules the dependency next up' do
      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_failed(reps[2])

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_failed(reps[4])

      expect(priority_queue.next).to eq(reps[4])
      expect { priority_queue.mark_failed(reps[1]) }
        .to raise_error(Nanoc::Core::Errors::DependencyCycle)
    end
  end

  context 'when there is a transitive dependency' do
    it 'schedules the dependency next up' do
      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_failed(reps[1])

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_failed(reps[2])

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_failed(reps[3])

      expect(priority_queue.next).to eq(reps[3])
      priority_queue.mark_failed(reps[4])

      expect(priority_queue.next).to eq(reps[4])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[3])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_ok

      expect(priority_queue.next).to be_nil
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
      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_failed(reps[2])

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_failed(reps[4])

      expect(priority_queue.next).to eq(reps[4])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_failed(reps[2])

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_failed(reps[3])

      expect(priority_queue.next).to eq(reps[3])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_ok

      expect(priority_queue.next).to be_nil
    end
  end

  context 'when there is an item with dependencies on an item that was delayed due to another dependency' do
    # 0 -> 3
    # 3 OK
    # 1 -> 0
    # 0 OK
    it 'schedules the dependency next up' do
      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_failed(reps[3])

      expect(priority_queue.next).to eq(reps[3])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_failed(reps[0])

      expect(priority_queue.next).to eq(reps[0])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[2])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[4])
      priority_queue.mark_ok

      expect(priority_queue.next).to eq(reps[1])
      priority_queue.mark_ok

      expect(priority_queue.next).to be_nil
    end
  end
end
