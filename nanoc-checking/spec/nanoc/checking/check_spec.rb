# frozen_string_literal: true

describe Nanoc::Checking::Check do
  let(:config) do
    Nanoc::Core::Configuration.new(
      dir: Dir.getwd,
      hash: config_hash,
    ).with_defaults
  end

  let(:config_hash) { {} }

  let(:reps) { Nanoc::Core::ItemRepRepo.new }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets: [],
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
    )
  end

  let(:items) { Nanoc::Core::ItemCollection.new(config, []) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config, []) }

  let(:view_context) do
    Nanoc::Core::ViewContextForCompilation.new(
      reps:,
      items:,
      dependency_tracker:,
      compilation_context:,
      compiled_content_store:,
    )
  end

  let(:compilation_context) do
    Nanoc::Core::CompilationContext.new(
      action_provider:,
      reps:,
      site:,
      compiled_content_cache:,
      compiled_content_store:,
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

  let(:compiled_content_cache) { Nanoc::Core::CompiledContentCache.new(config:) }
  let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }

  let(:dependency_tracker) { Nanoc::Core::DependencyTracker::Null.new }

  describe '.create' do
    let(:check_class) { described_class.named(:internal_links) }

    before do
      File.write('Rules', 'passthrough "/**/*"')
    end

    context 'output dir exists' do
      before do
        FileUtils.mkdir_p('output')
      end

      it 'does nor raise' do
        expect { check_class.create(site) }.not_to raise_error
      end
    end

    context 'output dir does not exist' do
      it 'raises' do
        expect { check_class.create(site) }
          .to raise_error(Nanoc::Checking::OutputDirNotFoundError)
      end
    end
  end

  describe '.define' do
    before do
      described_class.define(:spec_check_example_1) do
        add_issue('it’s totes bad')
      end

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
        output_filenames:,
        config: Nanoc::Core::ConfigView.new(config, view_context),
      )
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
        output_filenames:,
        config: Nanoc::Core::ConfigView.new(config, view_context),
      )
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
