# frozen_string_literal: true

describe Nanoc::Core::CompilationStages::Preprocess do
  let(:stage) do
    described_class.new(
      action_provider:,
      site:,
      dependency_store:,
      checksum_store:,
    )
  end

  let(:action_provider) do
    Class.new(Nanoc::Core::ActionProvider) do
      def self.for(_context)
        raise NotImplementedError
      end

      def initialize; end
    end.new
  end

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets: [],
      data_source:,
    )
  end

  let(:data_source) { Nanoc::Core::InMemoryDataSource.new(items, layouts) }
  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:items) { Nanoc::Core::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }

  let(:dependency_store) do
    Nanoc::Core::DependencyStore.new(items, layouts, config)
  end

  let(:checksum_store) do
    Nanoc::Core::ChecksumStore.new(config:, objects: items.to_a + layouts.to_a)
  end

  describe '#run' do
    subject { stage.run }

    context 'no preprocessing needed' do
      before do
        expect(action_provider).to receive(:need_preprocessing?).and_return(false)
      end

      it 'marks the site as preprocessed' do
        expect { subject }
          .to change(site, :preprocessed?)
          .from(false)
          .to(true)
      end

      it 'freezes the site' do # rubocop:disable RSpec/NoExpectationExample
        subject
      end
    end

    context 'preprocessing needed' do
      let(:new_item) { Nanoc::Core::Item.new('new item', {}, '/new.md') }
      let(:new_layout) { Nanoc::Core::Layout.new('new layout', {}, '/new.md') }

      before do
        expect(action_provider).to receive(:need_preprocessing?).and_return(true)

        expect(action_provider).to receive(:preprocess) do |site|
          site.data_source =
            Nanoc::Core::InMemoryDataSource.new(
              Nanoc::Core::ItemCollection.new(config, [new_item]),
              Nanoc::Core::LayoutCollection.new(config, [new_layout]),
            )
        end
      end

      it 'marks the site as preprocessed' do
        expect { subject }
          .to change(site, :preprocessed?)
          .from(false)
          .to(true)
      end

      it 'freezes the site' do
        expect { subject }
          .to change { site.config.frozen? }
          .from(false)
          .to(true)
      end

      it 'sets items on dependency store' do
        expect { subject }
          .to change { dependency_store.items.to_a }
          .from([])
          .to([new_item])
      end

      it 'sets layouts on dependency store' do
        expect { subject }
          .to change { dependency_store.layouts.to_a }
          .from([])
          .to([new_layout])
      end

      it 'sets data on checksum store' do
        expect { subject }
          .to change { checksum_store.objects.to_a }
          .from([])
          .to(contain_exactly(new_item, new_layout, config))
      end
    end
  end
end
