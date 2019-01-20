# frozen_string_literal: true

describe Nanoc::Int::Store do
  describe '#tmp_path_for' do
    context 'passing config' do
      subject { described_class.tmp_path_for(config: config, store_name: 'giraffes') }

      let(:code_snippets) { [] }
      let(:items) { [] }
      let(:layouts) { [] }

      def gen_hash(path)
        Digest::SHA1.hexdigest(File.absolute_path(path))[0..12]
      end

      let(:hash_output) { gen_hash('output') }
      let(:hash_output_default) { gen_hash('output-default') }
      let(:hash_output_staging) { gen_hash('output-staging') }
      let(:hash_output_production) { gen_hash('output-production') }

      context 'no env specified' do
        let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: config_hash).with_defaults.with_environment }

        context 'output dir is unspecified' do
          let(:config_hash) { {} }
          it { is_expected.to eql(Dir.getwd + "/tmp/nanoc/#{hash_output}/giraffes") }
        end

        context 'output dir at root is specified' do
          let(:config_hash) { { output_dir: 'output-default' } }
          it { is_expected.to eql(Dir.getwd + "/tmp/nanoc/#{hash_output_default}/giraffes") }
        end

        context 'output dir in default env is specified' do
          let(:config_hash) { { environments: { default: { output_dir: 'output-default' } } } }
          it { is_expected.to eql(Dir.getwd + "/tmp/nanoc/#{hash_output_default}/giraffes") }
        end

        context 'output dir in other env is specified' do
          let(:config_hash) { { environments: { production: { output_dir: 'output-production' } } } }
          it { is_expected.to eql(Dir.getwd + "/tmp/nanoc/#{hash_output}/giraffes") }
        end
      end

      context 'env specified' do
        let(:config) { Nanoc::Core::Configuration.new(env_name: 'staging', dir: Dir.getwd, hash: config_hash).with_defaults.with_environment }

        context 'output dir is unspecified' do
          let(:config_hash) { {} }
          it { is_expected.to eql(Dir.getwd + "/tmp/nanoc/#{hash_output}/giraffes") }
        end

        context 'output dir at root is specified' do
          let(:config_hash) { { output_dir: 'output-default' } }
          it { is_expected.to eql(Dir.getwd + "/tmp/nanoc/#{hash_output_default}/giraffes") }
        end

        context 'output dir in given env is specified' do
          let(:config_hash) { { environments: { staging: { output_dir: 'output-staging' } } } }
          it { is_expected.to eql(Dir.getwd + "/tmp/nanoc/#{hash_output_staging}/giraffes") }
        end

        context 'output dir in other env is specified' do
          let(:config_hash) { { environments: { production: { output_dir: 'output-production' } } } }
          it { is_expected.to eql(Dir.getwd + "/tmp/nanoc/#{hash_output}/giraffes") }
        end
      end
    end
  end

  let(:test_store_klass) do
    Class.new(Nanoc::Int::Store) do
      def data
        @data
      end

      def data=(new_data)
        @data = new_data
      end
    end
  end

  it 'deletes and reloads on error' do
    store = test_store_klass.new('test.db', 1)

    # Create
    store.load
    store.data = { fun: 'sure' }
    store.store

    # Test stored values
    store = test_store_klass.new('test.db', 1)
    store.load
    expect(store.data).to eq(fun: 'sure')

    # Mess up
    File.write('test.db', 'Damn {}#}%@}$^)@&$&*^#@ broken stores!!!')

    # Reload
    store = test_store_klass.new('test.db', 1)
    store.load
    expect(store.data).to be_nil
  end
end
