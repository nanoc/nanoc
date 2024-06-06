# frozen_string_literal: true

describe Nanoc::Core::BasicOutdatednessChecker do
  let(:basic_outdatedness_checker) do
    described_class.new(
      reps:,
      site:,
      checksum_store:,
      checksums:,
      dependency_store:,
      action_sequence_store:,
      action_sequences:,
    )
  end

  let(:checksum_store) { double(:checksum_store) }

  let(:checksums) do
    checksums = {}

    [items, layouts].each do |documents|
      documents.each do |document|
        checksums[[document.reference, :content]] =
          Nanoc::Core::Checksummer.calc_for_content_of(document)
        checksums[[document.reference, :each_attribute]] =
          Nanoc::Core::Checksummer.calc_for_each_attribute_of(document)
      end
    end

    [items, layouts, code_snippets].each do |objs|
      objs.each do |obj|
        checksums[obj.reference] =
          Nanoc::Core::Checksummer.calc(obj)
      end
    end

    checksums[config.reference] =
      Nanoc::Core::Checksummer.calc(config)
    checksums[[config.reference, :each_attribute]] =
      Nanoc::Core::Checksummer.calc_for_each_attribute_of(config)

    Nanoc::Core::ChecksumCollection.new(checksums)
  end

  let(:dependency_store) do
    Nanoc::Core::DependencyStore.new(items, layouts, config)
  end

  let(:items) { Nanoc::Core::ItemCollection.new(config, [item]) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }

  let(:code_snippets) { [] }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets:,
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
    )
  end

  let(:action_sequence_store) do
    Nanoc::Core::ActionSequenceStore.new(config:)
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

  describe 'basic outdatedness reasons' do
    subject { basic_outdatedness_checker.outdatedness_status_for(obj).reasons.first }

    let(:checksum_store) { Nanoc::Core::ChecksumStore.new(config:, objects: items.to_a + layouts.to_a) }

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

    before do
      checksum_store.add(item)

      allow(site).to receive_messages(code_snippets: [], config:)
    end

    context 'with item' do
      let(:obj) { item }

      context 'action sequence differs' do
        let(:new_action_sequence_for_item_rep) do
          Nanoc::Core::ActionSequenceBuilder.build do |b|
            b.add_filter(:super_erb, {})
          end
        end

        it 'is outdated due to rule differences' do
          expect(subject).to eql(Nanoc::Core::OutdatednessReasons::RulesModified)
        end
      end

      # …
    end

    context 'with item rep' do
      let(:obj) { item_rep }

      context 'action sequence differs' do
        let(:new_action_sequence_for_item_rep) do
          Nanoc::Core::ActionSequenceBuilder.build do |b|
            b.add_filter(:super_erb, {})
          end
        end

        it 'is outdated due to rule differences' do
          expect(subject).to eql(Nanoc::Core::OutdatednessReasons::RulesModified)
        end
      end

      # …
    end

    context 'with layout' do
      # …
    end
  end
end
