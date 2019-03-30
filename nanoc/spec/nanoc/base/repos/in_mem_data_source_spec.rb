# frozen_string_literal: true

describe Nanoc::Int::InMemDataSource, stdio: true do
  subject(:data_source) do
    described_class.new([], [], original_data_source)
  end

  let(:klass) do
    Class.new(Nanoc::DataSource) do
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
