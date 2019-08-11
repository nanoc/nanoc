# frozen_string_literal: true

describe Nanoc::Check do
  it 'is an alias' do
    expect(described_class).to equal(Nanoc::Checking::Check)
  end
end

describe Nanoc::Checking::Check do
  describe '.define' do
    before do
      described_class.define(:spec_check_example_1) do
        add_issue('it’s totes bad')
      end
    end

    let(:site) do
      Nanoc::Core::Site.new(
        config: config,
        code_snippets: code_snippets,
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )
    end

    let(:config)        { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
    let(:code_snippets) { [] }
    let(:items)         { Nanoc::Core::ItemCollection.new(config, []) }
    let(:layouts)       { Nanoc::Core::LayoutCollection.new(config, []) }

    before do
      FileUtils.mkdir_p('output')
      File.write('Rules', 'passthrough "/**/*"')
    end

    it 'is discoverable' do
      expect(described_class.named(:spec_check_example_1)).not_to be_nil
    end

    it 'runs properly' do
      check = described_class.named(:spec_check_example_1).create(site)
      check.run
      expect(check.issues.size).to eq(1)
      expect(check.issues.first.description).to eq('it’s totes bad')
    end
  end

  describe '.named' do
    it 'finds checks that exist' do
      expect(described_class.named(:internal_links)).not_to be_nil
    end

    it 'is nil for non-existent checks' do
      expect(described_class.named(:asdfaskjlfdalhsgdjf)).to be_nil
    end
  end

  describe '#output_filenames' do
    subject { check.output_filenames }

    let(:check) do
      described_class.new(
        output_filenames: output_filenames,
        config: Nanoc::ConfigView.new(config, view_context),
      )
    end

    let(:config) do
      Nanoc::Core::Configuration.new(
        dir: Dir.getwd,
        hash: config_hash,
      )
    end

    let(:config_hash) { {} }

    let(:view_context) do
      double(:view_context, dependency_tracker: dependency_tracker)
    end

    let(:dependency_tracker) do
      double(:dependency_tracker).tap do |dt|
        allow(dt).to receive(:bounce)
      end
    end

    let(:output_filenames) do
      [
        'output/foo.html',
        'output/foo.htm',
        'output/foo.xhtml',
        'output/foo.txt',
        'output/foo.htmlx',
        'output/foo.yhtml',
      ]
    end

    context 'when exclude_files is unset' do
      it { is_expected.to include('output/foo.htm') }
      it { is_expected.to include('output/foo.html') }
      it { is_expected.to include('output/foo.htmlx') }
      it { is_expected.to include('output/foo.txt') }
      it { is_expected.to include('output/foo.xhtml') }
      it { is_expected.to include('output/foo.yhtml') }
    end

    context 'when exclude_files is set' do
      let(:config_hash) do
        { checks: { all: { exclude_files: ['foo.xhtml'] } } }
      end

      it { is_expected.to include('output/foo.htm') }
      it { is_expected.to include('output/foo.html') }
      it { is_expected.to include('output/foo.htmlx') }
      it { is_expected.to include('output/foo.txt') }
      it { is_expected.to include('output/foo.yhtml') }

      it { is_expected.not_to include('output/foo.xhtml') }
    end
  end

  describe '#output_html_filenames' do
    subject { check.output_html_filenames }

    let(:check) do
      described_class.new(
        output_filenames: output_filenames,
        config: Nanoc::ConfigView.new(config, view_context),
      )
    end

    let(:config) do
      Nanoc::Core::Configuration.new(
        dir: Dir.getwd,
        hash: config_hash,
      )
    end

    let(:config_hash) { {} }

    let(:view_context) do
      double(:view_context, dependency_tracker: dependency_tracker)
    end

    let(:dependency_tracker) do
      double(:dependency_tracker).tap do |dt|
        allow(dt).to receive(:bounce)
      end
    end

    let(:output_filenames) do
      [
        'output/foo.html',
        'output/foo.htm',
        'output/foo.xhtml',
        'output/foo.txt',
        'output/foo.htmlx',
        'output/foo.yhtml',
      ]
    end

    context 'when exclude_files is unset' do
      it { is_expected.to include('output/foo.html') }
      it { is_expected.to include('output/foo.htm') }
      it { is_expected.to include('output/foo.xhtml') }

      it { is_expected.not_to include('output/foo.txt') }
      it { is_expected.not_to include('output/foo.htmlx') }
      it { is_expected.not_to include('output/foo.yhtml') }
    end

    context 'when exclude_files is set' do
      let(:config_hash) do
        { checks: { all: { exclude_files: ['foo.xhtml'] } } }
      end

      it { is_expected.to include('output/foo.html') }
      it { is_expected.to include('output/foo.htm') }

      it { is_expected.not_to include('output/foo.xhtml') }
      it { is_expected.not_to include('output/foo.txt') }
      it { is_expected.not_to include('output/foo.htmlx') }
      it { is_expected.not_to include('output/foo.yhtml') }
    end
  end
end
