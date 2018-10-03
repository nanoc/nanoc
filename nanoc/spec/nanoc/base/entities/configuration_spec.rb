# frozen_string_literal: true

describe Nanoc::Int::Configuration do
  let(:hash) { { foo: 'bar' } }
  let(:config) { described_class.new(hash: hash, dir: Dir.getwd) }

  describe '#key?' do
    subject { config.key?(key) }

    context 'non-existent key' do
      let(:key) { :donkey }
      it { is_expected.not_to be }
    end

    context 'existent key' do
      let(:key) { :foo }
      it { is_expected.to be }
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
      let(:config) { described_class.new(hash: hash, dir: Dir.getwd, env_name: 'giraffes') }

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

  describe '#merge' do
    let(:hash1) { { foo: { bar: 'baz', baz: ['biz'] } } }
    let(:hash2) { { foo: { bar: :boz, biz: 'buz' } } }
    let(:config1) { described_class.new(hash: hash1, dir: Dir.getwd) }
    let(:config2) { described_class.new(hash: hash2, dir: Dir.getwd) }

    subject { config1.merge(config2).to_h }

    it 'contains the recursive merge of both configurations' do
      expect(subject).to include(foo: { bar: :boz, baz: ['biz'], biz: 'buz' })
    end
  end

  context 'with environments defined' do
    let(:hash) { { foo: 'bar', environments: { test: { foo: 'test-bar' }, default: { foo: 'default-bar' } } } }
    let(:config) { described_class.new(hash: hash, dir: Dir.getwd, env_name: env_name).with_environment }

    subject { config }

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

      it 'passes' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid prune (auto_prune has incorrect type)' do
      let(:hash) { { prune: { auto_prune: 'please' } } }

      it 'passes' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid prune (exclude has incorrect type)' do
      let(:hash) { { prune: { exclude: 'nothing' } } }

      it 'passes' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid prune (exclude has items of incorrect type)' do
      let(:hash) { { prune: { exclude: [3000] } } }

      it 'passes' do
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

      it 'passes' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (internal_links has invalid type)' do
      let(:hash) do
        { checks: { internal_links: 123 } }
      end

      it 'passes' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (internal_links.exclude has invalid type)' do
      let(:hash) do
        { checks: { internal_links: { exclude: 'everything' } } }
      end

      it 'passes' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (external_links has invalid type)' do
      let(:hash) do
        { checks: { external_links: 123 } }
      end

      it 'passes' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (external_links.exclude has invalid type)' do
      let(:hash) do
        { checks: { external_links: { exclude: 'everything' } } }
      end

      it 'passes' do
        expect { subject }.to raise_error(JsonSchema::Error)
      end
    end

    context 'invalid checks (external_links.exclude_files has invalid type)' do
      let(:hash) do
        { checks: { external_links: { exclude_files: 'everything' } } }
      end

      it 'passes' do
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
