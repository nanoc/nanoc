# frozen_string_literal: true

describe Nanoc::Core::OutdatednessChecker do
  let(:outdatedness_checker) do
    described_class.new(
      site: site,
      checksum_store: checksum_store,
      checksums: checksums,
      dependency_store: dependency_store,
      action_sequence_store: action_sequence_store,
      action_sequences: action_sequences,
      reps: reps,
    )
  end

  let(:checksums) do
    Nanoc::Core::CompilationStages::CalculateChecksums.new(
      items: items_after,
      layouts: layouts_after,
      code_snippets: code_snippets,
      config: config,
    ).run
  end

  let(:dependency_store) do
    Nanoc::Core::DependencyStore.new(items_before, layouts_before, config)
  end

  let(:items_after) { items_before }
  let(:layouts_after) { layouts_before }

  let(:items_before) { Nanoc::Core::ItemCollection.new(config, [item]) }
  let(:layouts_before) { Nanoc::Core::LayoutCollection.new(config) }

  let(:code_snippets) { [] }

  let(:site) do
    Nanoc::Core::Site.new(
      config: config,
      code_snippets: code_snippets,
      data_source: Nanoc::Core::InMemoryDataSource.new(items_after, layouts_after),
    )
  end

  let(:action_sequence_store) do
    Nanoc::Core::ActionSequenceStore.new(config: config)
  end

  let(:old_action_sequence_for_item_rep) do
    Nanoc::Core::ActionSequenceBuilder.build do |b|
      b.add_filter(:erb, {})
    end
  end

  let(:new_action_sequence_for_item_rep) { old_action_sequence_for_item_rep }

  let(:action_sequences) do
    { item_rep => new_action_sequence_for_item_rep }
  end

  let(:reps) do
    Nanoc::Core::ItemRepRepo.new
  end

  let(:item_rep) { Nanoc::Core::ItemRep.new(item, :default) }
  let(:item) { Nanoc::Core::Item.new('stuff', {}, '/foo.md') }

  before do
    reps << item_rep
    action_sequence_store[item_rep] = old_action_sequence_for_item_rep.serialize
  end

  describe '#outdated_due_to_dependencies?' do
    subject { outdatedness_checker.send(:outdated_due_to_dependencies?, item) }

    let(:checksum_store) do
      Nanoc::Core::ChecksumStore.new(
        config: config,
        objects: items_before.to_a + layouts_before.to_a,
      )
    end

    let(:other_item) { Nanoc::Core::Item.new('other stuff', {}, '/other.md') }
    let(:other_item_rep) { Nanoc::Core::ItemRep.new(other_item, :default) }

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

    let(:old_action_sequence_for_other_item_rep) do
      Nanoc::Core::ActionSequenceBuilder.build do |b|
        b.add_filter(:erb, {})
      end
    end

    let(:new_action_sequence_for_other_item_rep) { old_action_sequence_for_other_item_rep }

    let(:action_sequences) do
      {
        item_rep => new_action_sequence_for_item_rep,
      }
    end

    before do
      checksum_store.add(item)
      checksum_store.add(config)

      allow(site).to receive(:code_snippets).and_return([])
      allow(site).to receive(:config).and_return(config)
    end

    context 'two items' do
      before do
        reps << other_item_rep

        action_sequence_store[other_item_rep] = old_action_sequence_for_other_item_rep.serialize

        checksum_store.add(other_item)
      end

      let(:items_before) do
        Nanoc::Core::ItemCollection.new(config, [item, other_item])
      end

      let(:action_sequences) do
        {
          item_rep => new_action_sequence_for_item_rep,
          other_item_rep => new_action_sequence_for_other_item_rep,
        }
      end

      context 'transitive dependency' do
        let(:distant_item) { Nanoc::Core::Item.new('distant stuff', {}, '/distant.md') }
        let(:distant_item_rep) { Nanoc::Core::ItemRep.new(distant_item, :default) }

        let(:items_before) do
          Nanoc::Core::ItemCollection.new(config, [item, other_item, distant_item])
        end

        let(:action_sequences) do
          {
            item_rep => new_action_sequence_for_item_rep,
            other_item_rep => new_action_sequence_for_other_item_rep,
            distant_item_rep => new_action_sequence_for_other_item_rep,
          }
        end

        before do
          reps << distant_item_rep
          checksum_store.add(distant_item)
          action_sequence_store[distant_item_rep] = old_action_sequence_for_other_item_rep.serialize
        end

        context 'on attribute + attribute' do
          before do
            dependency_store.record_dependency(item, other_item, attributes: true)
            dependency_store.record_dependency(other_item, distant_item, attributes: true)
          end

          context 'distant attribute changed' do
            before { distant_item.attributes[:title] = 'omg new title' }

            it 'has correct outdatedness of item' do
              expect(outdatedness_checker.send(:outdated_due_to_dependencies?, item)).to be(false)
            end

            it 'has correct outdatedness of other item' do
              expect(outdatedness_checker.send(:outdated_due_to_dependencies?, other_item)).to be(true)
            end
          end

          context 'distant raw content changed' do
            before { distant_item.content = Nanoc::Core::TextualContent.new('omg new content') }

            it 'has correct outdatedness of item' do
              expect(outdatedness_checker.send(:outdated_due_to_dependencies?, item)).to be(false)
            end

            it 'has correct outdatedness of other item' do
              expect(outdatedness_checker.send(:outdated_due_to_dependencies?, other_item)).to be(false)
            end
          end
        end

        context 'on compiled content + attribute' do
          before do
            dependency_store.record_dependency(item, other_item, compiled_content: true)
            dependency_store.record_dependency(other_item, distant_item, attributes: true)
          end

          context 'distant attribute changed' do
            before { distant_item.attributes[:title] = 'omg new title' }

            it 'has correct outdatedness of item' do
              expect(outdatedness_checker.send(:outdated_due_to_dependencies?, item)).to be(true)
            end

            it 'has correct outdatedness of other item' do
              expect(outdatedness_checker.send(:outdated_due_to_dependencies?, other_item)).to be(true)
            end
          end

          context 'distant raw content changed' do
            before { distant_item.content = Nanoc::Core::TextualContent.new('omg new content') }

            it 'has correct outdatedness of item' do
              expect(outdatedness_checker.send(:outdated_due_to_dependencies?, item)).to be(false)
            end

            it 'has correct outdatedness of other item' do
              expect(outdatedness_checker.send(:outdated_due_to_dependencies?, other_item)).to be(false)
            end
          end
        end
      end

      context 'only generic attribute dependency' do
        before do
          dependency_store.record_dependency(item, other_item, attributes: true)
        end

        context 'attribute changed' do
          before { other_item.attributes[:title] = 'omg new title' }

          it { is_expected.to be(true) }
        end

        context 'raw content changed' do
          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(false) }
        end

        context 'attribute + raw content changed' do
          before { other_item.attributes[:title] = 'omg new title' }

          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(true) }
        end

        context 'path changed' do
          let(:new_action_sequence_for_other_item_rep) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
              b.add_snapshot(:donkey, '/giraffe.txt', other_item_rep)
            end
          end

          it { is_expected.to be(false) }
        end
      end

      context 'only specific attribute dependency' do
        before do
          dependency_store.record_dependency(item, other_item, attributes: [:title])
        end

        context 'attribute changed' do
          before { other_item.attributes[:title] = 'omg new title' }

          it { is_expected.to be(true) }
        end

        context 'other attribute changed' do
          before { other_item.attributes[:subtitle] = 'tagline here' }

          it { is_expected.to be(false) }
        end

        context 'raw content changed' do
          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(false) }
        end

        context 'attribute + raw content changed' do
          before { other_item.attributes[:title] = 'omg new title' }

          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(true) }
        end

        context 'other attribute + raw content changed' do
          before { other_item.attributes[:subtitle] = 'tagline here' }

          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(false) }
        end

        context 'path changed' do
          let(:new_action_sequence_for_other_item_rep) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
              b.add_snapshot(:donkey, '/giraffe.txt', other_item_rep)
            end
          end

          it { is_expected.to be(false) }
        end
      end

      context 'generic dependency on config' do
        before do
          dependency_store.record_dependency(item, config, attributes: true)
        end

        context 'nothing changed' do
          it { is_expected.to be(false) }
        end

        context 'attribute changed' do
          before { config[:title] = 'omg new title' }

          it { is_expected.to be(true) }
        end

        context 'other attribute changed' do
          before { config[:subtitle] = 'tagline here' }

          it { is_expected.to be(true) }
        end
      end

      context 'specific dependency on config' do
        before do
          dependency_store.record_dependency(item, config, attributes: [:title])
        end

        context 'nothing changed' do
          it { is_expected.to be(false) }
        end

        context 'attribute changed' do
          before { config[:title] = 'omg new title' }

          it { is_expected.to be(true) }
        end

        context 'other attribute changed' do
          before { config[:subtitle] = 'tagline here' }

          it { is_expected.to be(false) }
        end
      end

      context 'only raw content dependency' do
        before do
          dependency_store.record_dependency(item, other_item, raw_content: true)
        end

        context 'attribute changed' do
          before { other_item.attributes[:title] = 'omg new title' }

          it { is_expected.to be(false) }
        end

        context 'raw content changed' do
          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(true) }
        end

        context 'attribute + raw content changed' do
          before { other_item.attributes[:title] = 'omg new title' }

          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(true) }
        end

        context 'path changed' do
          let(:new_action_sequence_for_other_item_rep) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
              b.add_snapshot(:donkey, '/giraffe.txt', other_item_rep)
            end
          end

          it { is_expected.to be(false) }
        end
      end

      context 'only path dependency' do
        before do
          dependency_store.record_dependency(item, other_item, raw_content: true)
        end

        context 'attribute changed' do
          before { other_item.attributes[:title] = 'omg new title' }

          it { is_expected.to be(false) }
        end

        context 'raw content changed' do
          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(true) }
        end

        context 'path changed' do
          let(:new_action_sequence_for_other_item_rep) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
              b.add_snapshot(:donkey, '/giraffe.txt', other_item_rep)
            end
          end

          it { is_expected.to be(false) }
        end
      end

      context 'attribute + raw content dependency' do
        before do
          dependency_store.record_dependency(item, other_item, attributes: true, raw_content: true)
        end

        context 'attribute changed' do
          before { other_item.attributes[:title] = 'omg new title' }

          it { is_expected.to be(true) }
        end

        context 'raw content changed' do
          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(true) }
        end

        context 'attribute + raw content changed' do
          before { other_item.attributes[:title] = 'omg new title' }

          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(true) }
        end

        context 'rules changed' do
          let(:new_action_sequence_for_other_item_rep) do
            Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
              b.add_filter(:donkey, {})
            end
          end

          it { is_expected.to be(false) }
        end
      end

      context 'attribute + other dependency' do
        before do
          dependency_store.record_dependency(item, other_item, attributes: true, path: true)
        end

        context 'attribute changed' do
          before { other_item.attributes[:title] = 'omg new title' }

          it { is_expected.to be(true) }
        end

        context 'raw content changed' do
          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(false) }
        end
      end

      context 'other dependency' do
        before do
          dependency_store.record_dependency(item, other_item, path: true)
        end

        context 'attribute changed' do
          before { other_item.attributes[:title] = 'omg new title' }

          it { is_expected.to be(false) }
        end

        context 'raw content changed' do
          before { other_item.content = Nanoc::Core::TextualContent.new('omg new content') }

          it { is_expected.to be(false) }
        end
      end
    end

    context 'only item collection dependency' do
      context 'dependency on any new item' do
        before do
          dependency_tracker = Nanoc::Core::DependencyTracker.new(dependency_store)
          dependency_tracker.enter(item)
          dependency_tracker.bounce(items_after, raw_content: true)
          dependency_store.store
        end

        context 'nothing changed' do
          it { is_expected.to be(false) }
        end

        context 'item added' do
          let(:new_item) { Nanoc::Core::Item.new('stuff', {}, '/newblahz.md') }
          let(:new_item_rep) { Nanoc::Core::ItemRep.new(new_item, :default) }

          let(:items_after) do
            Nanoc::Core::ItemCollection.new(config, items_before.to_a + [new_item])
          end

          let(:action_sequences) do
            super().merge({ new_item_rep => old_action_sequence_for_item_rep })
          end

          before do
            reps << new_item_rep

            dependency_store.items = items_after
            dependency_store.load
          end

          it { is_expected.to be(true) }
        end

        context 'item removed' do
          let(:items_after) { Nanoc::Core::ItemCollection.new(config, []) }

          before do
            dependency_store.items = items_after
            dependency_store.load
          end

          it { is_expected.to be(false) }
        end
      end

      context 'dependency on specific new items (string)' do
        before do
          dependency_tracker = Nanoc::Core::DependencyTracker.new(dependency_store)
          dependency_tracker.enter(item)
          dependency_tracker.bounce(items_after, raw_content: ['/new*'])
          dependency_store.store
        end

        context 'nothing changed' do
          it { is_expected.to be(false) }
        end

        context 'matching item added' do
          let(:new_item) { Nanoc::Core::Item.new('stuff', {}, '/newblahz.md') }
          let(:new_item_rep) { Nanoc::Core::ItemRep.new(new_item, :default) }

          let(:items_after) do
            Nanoc::Core::ItemCollection.new(config, items_before.to_a + [new_item])
          end

          let(:action_sequences) do
            super().merge({ new_item_rep => old_action_sequence_for_item_rep })
          end

          before do
            reps << new_item_rep

            dependency_store.items = items_after
            dependency_store.load
          end

          it { is_expected.to be(true) }
        end

        context 'non-matching item added' do
          let(:new_item) { Nanoc::Core::Item.new('stuff', {}, '/nublahz.md') }
          let(:new_item_rep) { Nanoc::Core::ItemRep.new(new_item, :default) }

          let(:items_after) do
            Nanoc::Core::ItemCollection.new(config, items_before.to_a + [new_item])
          end

          before do
            reps << new_item_rep

            dependency_store.items = items_after
            dependency_store.load
          end

          it { is_expected.to be(false) }
        end

        context 'item removed' do
          let(:items_after) { Nanoc::Core::ItemCollection.new(config, []) }

          before do
            dependency_store.items = items_after
            dependency_store.load
          end

          it { is_expected.to be(false) }
        end
      end

      context 'dependency on specific new items (regex)' do
        before do
          dependency_tracker = Nanoc::Core::DependencyTracker.new(dependency_store)
          dependency_tracker.enter(item)
          dependency_tracker.bounce(items_after, raw_content: [%r{^/new.*}])
          dependency_store.store
        end

        context 'nothing changed' do
          it { is_expected.to be(false) }
        end

        context 'matching item added' do
          let(:new_item) { Nanoc::Core::Item.new('stuff', {}, '/newblahz.md') }
          let(:new_item_rep) { Nanoc::Core::ItemRep.new(new_item, :default) }

          let(:items_after) do
            Nanoc::Core::ItemCollection.new(config, items_before.to_a + [new_item])
          end

          let(:action_sequences) do
            super().merge({ new_item_rep => old_action_sequence_for_item_rep })
          end

          before do
            reps << new_item_rep

            dependency_store.items = items_after
            dependency_store.load
          end

          it { is_expected.to be(true) }
        end

        context 'non-matching item added' do
          let(:new_item) { Nanoc::Core::Item.new('stuff', {}, '/nublahz.md') }
          let(:new_item_rep) { Nanoc::Core::ItemRep.new(new_item, :default) }

          let(:items_after) do
            Nanoc::Core::ItemCollection.new(config, items_before.to_a + [new_item])
          end

          let(:action_sequences) do
            super().merge({ new_item_rep => old_action_sequence_for_item_rep })
          end

          before do
            dependency_store.items = items_after
            dependency_store.load
          end

          it { is_expected.to be(false) }
        end

        context 'item removed' do
          let(:items_after) { Nanoc::Core::ItemCollection.new(config, []) }

          before do
            dependency_store.items = items_after
            dependency_store.load
          end

          it { is_expected.to be(false) }
        end

        context 'dependency on specific new items (attribute)' do
          before do
            dependency_tracker = Nanoc::Core::DependencyTracker.new(dependency_store)
            dependency_tracker.enter(item)
            dependency_tracker.bounce(items_after, attributes: { kind: 'note' })
            dependency_store.store
          end

          context 'nothing changed' do
            it { is_expected.to be(false) }
          end

          context 'matching item added' do
            let(:new_item) { Nanoc::Core::Item.new('stuff', { kind: 'note' }, '/new-note.md') }
            let(:new_item_rep) { Nanoc::Core::ItemRep.new(new_item, :default) }

            let(:items_after) do
              Nanoc::Core::ItemCollection.new(config, items_before.to_a + [new_item])
            end

            let(:action_sequences) do
              super().merge({ new_item_rep => old_action_sequence_for_item_rep })
            end

            before do
              reps << new_item_rep

              dependency_store.items = items_after
              dependency_store.load
            end

            it { is_expected.to be(true) }
          end

          context 'non-matching item added' do
            let(:new_item) { Nanoc::Core::Item.new('stuff', { kind: 'article' }, '/nu-article.md') }
            let(:new_item_rep) { Nanoc::Core::ItemRep.new(new_item, :default) }

            let(:items_after) do
              Nanoc::Core::ItemCollection.new(config, items_before.to_a + [new_item])
            end

            let(:action_sequences) do
              super().merge({ new_item_rep => old_action_sequence_for_item_rep })
            end

            before do
              reps << new_item_rep

              dependency_store.items = items_after
              dependency_store.load
            end

            it { is_expected.to be(false) }
          end

          context 'item removed' do
            let(:items_after) { Nanoc::Core::ItemCollection.new(config, []) }

            before do
              dependency_store.items = items_after
              dependency_store.load
            end

            it { is_expected.to be(false) }
          end
        end
      end
    end

    context 'only layout collection dependency' do
      context 'dependency on any new layout' do
        before do
          dependency_tracker = Nanoc::Core::DependencyTracker.new(dependency_store)
          dependency_tracker.enter(item)
          dependency_tracker.bounce(layouts_after, raw_content: true)
          dependency_store.store
        end

        context 'nothing changed' do
          it { is_expected.to be(false) }
        end

        context 'layout added' do
          let(:new_layout) { Nanoc::Core::Layout.new('stuff', {}, '/newblahz.md') }

          let(:layouts_after) do
            Nanoc::Core::LayoutCollection.new(config, layouts_before.to_a + [new_layout])
          end

          let(:action_sequences) do
            seq = Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
            end

            super().merge({ new_layout => seq })
          end

          before do
            dependency_store.layouts = layouts_after
            dependency_store.load
          end

          it { is_expected.to be(true) }
        end

        context 'layout removed' do
          let(:layouts_after) { Nanoc::Core::LayoutCollection.new(config, []) }

          before do
            dependency_store.layouts = layouts_after
            dependency_store.load
          end

          it { is_expected.to be(false) }
        end
      end

      context 'dependency on specific new layouts (string)' do
        before do
          dependency_tracker = Nanoc::Core::DependencyTracker.new(dependency_store)
          dependency_tracker.enter(item)
          dependency_tracker.bounce(layouts_after, raw_content: ['/new*'])
          dependency_store.store
        end

        context 'nothing changed' do
          it { is_expected.to be(false) }
        end

        context 'matching layout added' do
          let(:new_layout) { Nanoc::Core::Layout.new('stuff', {}, '/newblahz.md') }

          let(:layouts_after) do
            Nanoc::Core::LayoutCollection.new(config, layouts_before.to_a + [new_layout])
          end

          let(:action_sequences) do
            seq = Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
            end

            super().merge({ new_layout => seq })
          end

          before do
            dependency_store.layouts = layouts_after
            dependency_store.load
          end

          it { is_expected.to be(true) }
        end

        context 'non-matching layout added' do
          let(:new_layout) { Nanoc::Core::Layout.new('stuff', {}, '/nublahz.md') }

          let(:layouts_after) do
            Nanoc::Core::LayoutCollection.new(config, layouts_before.to_a + [new_layout])
          end

          let(:action_sequences) do
            seq = Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
            end

            super().merge({ new_layout => seq })
          end

          before do
            dependency_store.layouts = layouts_after
            dependency_store.load
          end

          it { is_expected.to be(false) }
        end

        context 'layout removed' do
          let(:layouts_after) { Nanoc::Core::LayoutCollection.new(config, []) }

          before do
            dependency_store.layouts = layouts_after
            dependency_store.load
          end

          it { is_expected.to be(false) }
        end
      end

      context 'dependency on specific new layouts (regex)' do
        before do
          dependency_tracker = Nanoc::Core::DependencyTracker.new(dependency_store)
          dependency_tracker.enter(item)
          dependency_tracker.bounce(layouts_after, raw_content: [%r{^/new.*}])
          dependency_store.store
        end

        context 'nothing changed' do
          it { is_expected.to be(false) }
        end

        context 'matching layout added' do
          let(:new_layout) { Nanoc::Core::Layout.new('stuff', {}, '/newblahz.md') }

          let(:layouts_after) do
            Nanoc::Core::LayoutCollection.new(config, layouts_before.to_a + [new_layout])
          end

          let(:action_sequences) do
            seq = Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
            end

            super().merge({ new_layout => seq })
          end

          before do
            dependency_store.layouts = layouts_after
            dependency_store.load
          end

          it { is_expected.to be(true) }
        end

        context 'non-matching layout added' do
          let(:new_layout) { Nanoc::Core::Layout.new('stuff', {}, '/nublahz.md') }

          let(:layouts_after) do
            Nanoc::Core::LayoutCollection.new(config, layouts_before.to_a + [new_layout])
          end

          let(:action_sequences) do
            seq = Nanoc::Core::ActionSequenceBuilder.build do |b|
              b.add_filter(:erb, {})
            end

            super().merge({ new_layout => seq })
          end

          before do
            dependency_store.layouts = layouts_after
            dependency_store.load
          end

          it { is_expected.to be(false) }
        end

        context 'layout removed' do
          let(:layouts_after) { Nanoc::Core::LayoutCollection.new(config, []) }

          before do
            dependency_store.layouts = layouts_after
            dependency_store.load
          end

          it { is_expected.to be(false) }
        end
      end
    end
  end
end
