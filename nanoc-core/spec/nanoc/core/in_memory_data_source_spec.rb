# frozen_string_literal: true

describe Nanoc::Core::InMemoryDataSource, stdio: true do
  subject(:data_source) do
    described_class.new(items, layouts, original_data_source)
  end

  let(:items) { Nanoc::Core::ItemCollection.new(config, []) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config, []) }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd) }

  let(:klass) do
    Class.new(Nanoc::Core::DataSource) do
      def item_changes
        %i[one_foo one_bar]
      end

      def layout_changes
        %i[one_foo one_bar]
      end
    end
  end

  let(:original_data_source) do
    klass.new({}, nil, nil, {})
  end

  describe '#item_changes' do
    subject { data_source.item_changes }

    it 'yields changes from the original' do
      expect(subject).to eq(original_data_source.item_changes)
    end
  end

  describe '#layout_changes' do
    subject { data_source.layout_changes }

    it 'yields changes from the original' do
      expect(subject).to eq(original_data_source.layout_changes)
    end
  end
end
