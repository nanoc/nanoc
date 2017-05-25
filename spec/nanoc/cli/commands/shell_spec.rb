# frozen_string_literal: true

describe Nanoc::CLI::Commands::Shell, site: true, stdio: true do
  describe '#run' do
    before do
      # Prevent double-loading
      expect(Nanoc::CLI).to receive(:setup)

      File.write('content/hello.md', 'Hello!')

      File.write('Rules', <<~EOS)
        preprocess do
          @items['/hello.*'].raw_content = 'Better hello!'
        end

        compile '/**/*' do
        end
      EOS
    end

    it 'can be invoked' do
      expect_any_instance_of(Nanoc::Int::Context).to receive(:pry) do |ctx|
        expect(ctx.items.size).to eq(1)
        expect(ctx.items.to_a[0].unwrap.content.string).to eq('Hello!')
      end

      Nanoc::CLI.run(['shell'])
    end

    it 'will preprocess if requested' do
      expect_any_instance_of(Nanoc::Int::Context).to receive(:pry) do |ctx|
        expect(ctx.items.size).to eq(1)
        expect(ctx.items.to_a[0].unwrap.content.string).to eq('Better hello!')
      end

      Nanoc::CLI.run(['shell', '--preprocess'])
    end
  end

  describe '#env_for_site' do
    subject { described_class.env_for_site(site) }

    before do
      File.write('content/hello.md', 'Hello!')
      File.write('layouts/default.erb', '<title>MY SITE!</title><%= yield %>')
    end

    let(:site) do
      Nanoc::Int::SiteLoader.new.new_from_cwd
    end

    it 'returns views' do
      expect(subject[:items]).to be_a(Nanoc::ItemCollectionWithRepsView)
      expect(subject[:layouts]).to be_a(Nanoc::LayoutCollectionView)
      expect(subject[:config]).to be_a(Nanoc::ConfigView)
    end

    it 'returns correct items' do
      expect(subject[:items].size).to eq(1)
      expect(subject[:items].first.identifier.to_s).to eq('/hello.md')
    end

    it 'returns correct layouts' do
      expect(subject[:layouts].size).to eq(1)
      expect(subject[:layouts].first.identifier.to_s).to eq('/default.erb')
    end

    it 'returns items with reps' do
      expect(subject[:items].first.reps).not_to be_nil
      expect(subject[:items].first.reps.first.name).to eq(:default)
    end

    it 'returns items with rep paths' do
      expect(subject[:items].first.reps.first.path).to eq('/hello.md')
    end
  end
end
