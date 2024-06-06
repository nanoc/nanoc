# frozen_string_literal: true

describe Nanoc::Core::Configuration do
  let(:hash) { { foo: 'bar' } }
  let(:config) { described_class.new(hash:, dir: Dir.getwd) }

  describe '#key?' do
    subject { config.key?(key) }

    context 'non-existent key' do
      let(:key) { :donkey }

      it { is_expected.to be(false) }
    end

    context 'existent key' do
      let(:key) { :foo }

      it { is_expected.to be(true) }
    end
  end

  describe '#with_defaults' do
    subject { config.with_defaults }

    context 'no env' do
      it 'has a default output_dir' do
        expect(subject[:output_dir]).to eql('output')
      end
    end

    context 'env' do
      let(:config) { described_class.new(hash:, dir: Dir.getwd, env_name: 'giraffes') }

      it 'retains the env name' do
        expect(subject.env_name).to eql('giraffes')
      end
    end
  end

  describe '#output_dir' do
    subject { config.with_defaults.output_dir }

    context 'not explicitly defined' do
      let(:hash) { { foo: 'bar' } }

      it { is_expected.to eql(Dir.getwd + '/output') }
    end

    context 'explicitly defined, top-level' do
      let(:hash) { { foo: 'bar', output_dir: 'build' } }

      it { is_expected.to eql(Dir.getwd + '/build') }
    end
  end

  describe '#output_dirs' do
    subject { config.with_defaults.output_dirs }

    let(:hash) do
      {
        output_dir: 'output_toplevel',
        environments: {
          default: {
            output_dir: 'output_default',
          },
          production: {
            output_dir: 'output_prod',
          },
          staging: {
            output_dir: 'output_staging',
          },
          other: {},
        },
      }
    end

    it 'contains both top-level and default output dir' do
      expect(subject).to include(Dir.getwd + '/output_toplevel')
      expect(subject).to include(Dir.getwd + '/output_default')
    end

    it 'does not contain nil' do
      expect(subject).not_to include(nil)
    end

    it 'contains all other output dirs' do
      expect(subject).to include(Dir.getwd + '/output_staging')
      expect(subject).to include(Dir.getwd + '/output_prod')
    end
  end

  describe '#dig' do
    subject { config.dig(:foo, :bar, :baz) }

    let(:hash) do
      { foo: { bar: { baz: 1 } } }
    end

    let(:config) { described_class.new(hash:, dir: Dir.getwd) }

    it 'works like Hash#dig' do
      expect(subject).to eq(1)
    end
  end

  describe '#fetch' do
    let(:hash) { { foo: 123 } }
    let(:config) { described_class.new(hash:, dir: Dir.getwd) }

    context 'key exists' do
      subject { config.fetch(:foo) }

      it { is_expected.to eq(123) }
    end

    context 'key does not exist, and called without fallback nor block' do
      subject { config.fetch(:bar) }

      it 'raises KeyError' do
        expect { subject }.to raise_error(KeyError)
      end
    end

    context 'key does not exist, and called with fallback' do
      subject { config.fetch(:bar, 1000) }

      it { is_expected.to eq(1000) }
    end

    context 'key does not exist, and called with block' do
      subject { config.fetch(:bar) { 2000 } } # rubocop:disable Style/RedundantFetchBlock

      it { is_expected.to eq(2000) }
    end
  end

  describe '#[]' do
    let(:hash) { { foo: 123 } }
    let(:config) { described_class.new(hash:, dir: Dir.getwd) }

    context 'key exists' do
      subject { config[:foo] }

      it { is_expected.to eq(123) }
    end

    context 'key does not exist' do
      subject { config[:bar] }

      it { is_expected.to be_nil }
    end
  end

  describe '#[]=' do
    subject { config[:foo] = 234 }

    let(:hash) { { foo: 123 } }
    let(:config) { described_class.new(hash:, dir: Dir.getwd) }

    it 'modifies' do
      expect { subject }
        .to change { config[:foo] }
        .from(123)
        .to(234)
    end
  end

  describe '#attributes' do
    subject { config.attributes }

    let(:hash) { { foo: 123 } }
    let(:config) { described_class.new(hash:, dir: Dir.getwd) }

    it 'returns itself as a hash' do
      expect(subject).to eq(foo: 123)
    end
  end

  describe '#without' do
    subject { config.without(:foo) }

    let(:hash) { { foo: 123, bar: 234 } }
    let(:config) { described_class.new(hash:, dir: Dir.getwd) }

    it 'returns a new config' do
      expect(subject).to be_a(described_class)
    end

    it 'removes only the requested key' do
      expect(config.key?(:foo)).to be(true)
      expect(subject.key?(:foo)).to be(false)
    end

    it 'retains dir' do
      expect(subject.dir).to eq(config.dir)
    end

    it 'retains env_name' do
      expect(subject.env_name).to eq(config.env_name)
    end
  end

  describe '#update' do
    subject { config.update(other_hash) }

    let(:hash) { { foo: 100, bar: 200 } }
    let(:config) { described_class.new(hash:, dir: Dir.getwd) }
    let(:other_hash) { { bar: 300, qux: 400 } }

    it 'retains :foo' do
      expect { subject }
        .not_to change { config[:foo] }
        .from(100)
    end

    it 'updates :bar' do
      expect { subject }
        .to change { config[:bar] }
        .from(200)
        .to(300)
    end

    it 'adds :qux' do
      expect { subject }
        .to change { config[:qux] }
        .from(nil)
        .to(400)
    end
  end

  describe '#freeze' do
    subject { config.freeze }

    let(:hash) { { foo: { bar: 100 } } }
    let(:config) { described_class.new(hash:, dir: Dir.getwd) }

    it 'freezes' do
      expect { subject }
        .to change(config, :frozen?)
        .from(false)
        .to(true)
    end

    it 'freezes children' do
      expect { subject }
        .to change { config[:foo].frozen? }
        .from(false)
        .to(true)
    end
  end

  describe '#action_provider' do
    subject { config.action_provider }

    let(:hash) { { foo: { bar: 100 } } }
    let(:config) { described_class.new(hash:, dir: Dir.getwd) }

    context 'no action_provider key present' do
      let(:hash) { { foo: 123 } }

      it 'raises' do
        # Maybe not the best… but it works for now
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context 'action_provider key present' do
      let(:hash) { { foo: 123, action_provider: 'rulez' } }

      it { is_expected.to eq(:rulez) }
    end
  end

  describe '#reference' do
    subject { config.reference }

    let(:hash) { { foo: { bar: 100 } } }
    let(:config) { described_class.new(hash:, dir: Dir.getwd) }

    it { is_expected.to eq('configuration') }
  end

  describe '#inspect' do
    subject { config.inspect }

    let(:hash) { { foo: { bar: 100 } } }
    let(:config) { described_class.new(hash:, dir: Dir.getwd) }

    it { is_expected.to eq('<Nanoc::Core::Configuration>') }
  end

  describe '#merge' do
    subject { config1.merge(config2).to_h }

    let(:hash1) { { foo: { bar: 'baz', baz: ['biz'] } } }
    let(:hash2) { { foo: { bar: :boz, biz: 'buz' } } }
    let(:config1) { described_class.new(hash: hash1, dir: Dir.getwd) }
    let(:config2) { described_class.new(hash: hash2, dir: Dir.getwd) }

    it 'contains the recursive merge of both configurations' do
      expect(subject).to include(foo: { bar: :boz, baz: ['biz'], biz: 'buz' })
    end
  end

  context 'with environments defined' do
    subject { config }

    let(:hash) { { foo: 'bar', environments: { test: { foo: 'test-bar' }, default: { foo: 'default-bar' } } } }
    let(:config) { described_class.new(hash:, dir: Dir.getwd, env_name:).with_environment }

    context 'with existing environment' do
      let(:env_name) { 'test' }

      it 'inherits options from given environment' do
        expect(subject[:foo]).to eq('test-bar')
      end
    end

    context 'with unknown environment' do
      let(:env_name) { 'wtf' }

      it 'does not inherits options from any environment' do
        expect(subject[:foo]).to eq('bar')
      end
    end

    context 'without given environment' do
      let(:env_name) { nil }

      it 'inherits options from default environment' do
        expect(subject[:foo]).to eq('default-bar')
      end
    end
  end

  describe 'validation' do
    subject { config }

    context 'valid text_extensions' do
      let(:hash) { { text_extensions: ['md'] } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'invalid text_extensions (not an array)' do
      let(:hash) { { text_extensions: 123 } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid text_extensions (array, but with other things)' do
      let(:hash) { { text_extensions: [123] } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'valid output_dir' do
      let(:hash) { { output_dir: 'output' } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'invalid output_dir' do
      let(:hash) { { output_dir: 123 } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'valid index_filenames' do
      let(:hash) { { index_filenames: ['index.html'] } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'invalid index_filenames (not an array)' do
      let(:hash) { { index_filenames: 123 } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid index_filenames (array, but with other things)' do
      let(:hash) { { index_filenames: [123] } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'valid enable_output_diff' do
      let(:hash) { { enable_output_diff: false } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'invalid enable_output_diff' do
      let(:hash) { { enable_output_diff: 'nope' } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'valid prune (empty)' do
      let(:hash) { { prune: {} } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'valid prune (full)' do
      let(:hash) { { prune: { auto_prune: true, exclude: ['oink'] } } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'invalid prune (not a hash)' do
      let(:hash) { { prune: 'please' } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid prune (auto_prune has incorrect type)' do
      let(:hash) { { prune: { auto_prune: 'please' } } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid prune (exclude has incorrect type)' do
      let(:hash) { { prune: { exclude: 'nothing' } } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid prune (exclude has items of incorrect type)' do
      let(:hash) { { prune: { exclude: [3000] } } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'valid commands_dirs' do
      let(:hash) { { commands_dirs: ['commands'] } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'invalid commands_dirs (not an array)' do
      let(:hash) { { commands_dirs: 123 } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid commands_dirs (array, but with other things)' do
      let(:hash) { { commands_dirs: [123] } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'valid lib_dirs' do
      let(:hash) { { lib_dirs: ['lib'] } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'invalid lib_dirs (not an array)' do
      let(:hash) { { lib_dirs: 123 } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid lib_dirs (array, but with other things)' do
      let(:hash) { { lib_dirs: [123] } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'valid data_sources (full)' do
      let(:hash) { { data_sources: [{ type: 'something', items_root: 'itemz/' }] } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'valid data_sources (null items_root)' do
      let(:hash) { { data_sources: [{ type: 'something', items_root: nil }] } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'valid data_sources (null layouts_root)' do
      let(:hash) { { data_sources: [{ type: 'something', layouts_root: nil }] } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'valid data_sources (empty list)' do
      let(:hash) { { data_sources: [] } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'valid data_sources (list with empty hashes)' do
      let(:hash) { { data_sources: [{}] } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'invalid data_sources (not an array)' do
      let(:hash) { { data_sources: 'all of them please' } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid data_sources (items have invalid type)' do
      let(:hash) { { data_sources: ['all of them please'] } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid data_sources (items have invalid type field)' do
      let(:hash) { { data_sources: [{ type: 17 }] } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid data_sources (items have invalid items_root field)' do
      let(:hash) { { data_sources: [{ items_root: 17 }] } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid data_sources (items have invalid layouts_root field)' do
      let(:hash) { { data_sources: [{ layouts_root: 17 }] } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'valid string_pattern_type' do
      let(:hash) { { string_pattern_type: 'glob' } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'invalid string_pattern_type (incorrect type)' do
      let(:hash) { { string_pattern_type: 16 } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid string_pattern_type (not in enum)' do
      let(:hash) { { string_pattern_type: 'pretty' } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'valid checks (full)' do
      let(:hash) do
        {
          checks: {
            internal_links: {
              exclude: ['oink'],
            },
            external_links: {
              exclude: ['abc'],
              exclude_files: ['xyz'],
            },
          },
        }
      end

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'invalid checks (invalid type)' do
      let(:hash) do
        { checks: 123 }
      end

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (all has invalid type)' do
      let(:hash) do
        { checks: { all: 123 } }
      end

      it 'passes' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (all.exclude_files has invalid type)' do
      let(:hash) do
        { checks: { all: { exclude_files: 'everything' } } }
      end

      it 'passes' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (internal_links has invalid type)' do
      let(:hash) do
        { checks: { internal_links: 123 } }
      end

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (internal_links.exclude has invalid type)' do
      let(:hash) do
        { checks: { internal_links: { exclude: 'everything' } } }
      end

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (external_links has invalid type)' do
      let(:hash) do
        { checks: { external_links: 123 } }
      end

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (external_links.exclude has invalid type)' do
      let(:hash) do
        { checks: { external_links: { exclude: 'everything' } } }
      end

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (external_links.exclude_files has invalid type)' do
      let(:hash) do
        { checks: { external_links: { exclude_files: 'everything' } } }
      end

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'valid environments' do
      let(:hash) { { environments: { production: {} } } }

      it 'passes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'invalid environments (not an object)' do
      let(:hash) { { environments: nil } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid environments (values are not objects)' do
      let(:hash) { { environments: { production: nil } } }

      it 'fails' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end
  end
end
