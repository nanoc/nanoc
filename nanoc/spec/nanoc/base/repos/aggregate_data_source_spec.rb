# frozen_string_literal: true

describe Nanoc::Int::AggregateDataSource, stdio: true do
  let(:klass_1) do
    Class.new(Nanoc::DataSource) do
      def items
        [Nanoc::Core::Item.new('One', {}, '/one.md')]
      end

      def item_changes
        %i[one_foo one_bar]
      end

      def layouts
        [Nanoc::Core::Layout.new('One', {}, '/one.md')]
      end

      def layout_changes
        %i[one_foo one_bar]
      end
    end
  end

  let(:klass_2) do
    Class.new(Nanoc::DataSource) do
      def items
        [Nanoc::Core::Item.new('Two', {}, '/two.md')]
      end

      def item_changes
        %i[two_foo two_bar]
      end

      def layouts
        [Nanoc::Core::Layout.new('Two', {}, '/two.md')]
      end

      def layout_changes
        %i[two_foo two_bar]
      end
    end
  end

  let(:data_source_1) do
    klass_1.new({}, nil, nil, {})
  end

  let(:data_source_2) do
    klass_2.new({}, nil, nil, {})
  end

  subject(:data_source) do
    described_class.new([data_source_1, data_source_2], {})
  end

  describe '#items' do
    subject { data_source.items }

    it 'contains all items' do
      expect(subject).to match_array(data_source_1.items + data_source_2.items)
    end
  end

  describe '#layouts' do
    subject { data_source.layouts }

    it 'contains all layouts' do
      expect(subject).to match_array(data_source_1.layouts + data_source_2.layouts)
    end
  end

  describe '#item_changes' do
    subject { data_source.item_changes }

    it 'yields changes from both' do
      expect(subject).to match_array(data_source_1.item_changes + data_source_2.item_changes)
    end
  end

  describe '#layout_changes' do
    subject { data_source.layout_changes }

    it 'yields changes from both' do
      expect(subject).to match_array(data_source_1.layout_changes + data_source_2.layout_changes)
    end
  end
end
