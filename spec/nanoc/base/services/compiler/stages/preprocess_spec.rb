# frozen_string_literal: true

describe Nanoc::Int::Compiler::Stages::Preprocess do
  let(:stage) do
    described_class.new(
      action_provider: action_provider,
      site: site,
      dependency_store: dependency_store,
      checksum_store: checksum_store,
    )
  end

  let(:action_provider) do
    double(:action_provider)
  end

  let(:site) do
    Nanoc::Int::Site.new(
      config: config,
      code_snippets: [],
      data_source: data_source,
    )
  end

  let(:data_source) { Nanoc::Int::InMemDataSource.new(items, layouts) }
  let(:config) { Nanoc::Int::Configuration.new.with_defaults }
  let(:items) { Nanoc::Int::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Int::LayoutCollection.new(config) }

  let(:dependency_store) do
    Nanoc::Int::DependencyStore.new(items, layouts, config)
  end

  let(:checksum_store) do
    Nanoc::Int::ChecksumStore.new(site: site, objects: items.to_a + layouts.to_a)
  end

  describe '#run' do
    subject { stage.run }

    context 'no preprocessing needed' do
      before do
        expect(action_provider).to receive(:need_preprocessing?).and_return(false)
      end

      it 'marks the site as preprocessed' do
        expect { subject }
          .to change { site.preprocessed? }
          .from(false)
          .to(true)
      end

      it 'freezes the site' do
        subject
      end
    end

    context 'preprocessing needed' do
      let(:new_item) { Nanoc::Int::Item.new('new item', {}, '/new.md') }
      let(:new_layout) { Nanoc::Int::Layout.new('new layout', {}, '/new.md') }

      before do
        expect(action_provider).to receive(:need_preprocessing?).and_return(true)

        expect(action_provider).to receive(:preprocess) do |site|
          site.data_source =
            Nanoc::Int::InMemDataSource.new(
              Nanoc::Int::ItemCollection.new(config, [new_item]),
              Nanoc::Int::LayoutCollection.new(config, [new_layout]),
            )
        end
      end

      it 'marks the site as preprocessed' do
        expect { subject }
          .to change { site.preprocessed? }
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
          .to(match_array([new_item, new_layout, config]))
      end
    end
  end
end
