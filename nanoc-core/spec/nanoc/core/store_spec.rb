# frozen_string_literal: true

describe Nanoc::Core::Store do
  let(:test_store_klass) do
    Class.new(Nanoc::Core::Store) do
      def data
        @data
      end

      def data=(new_data)
        @data = new_data
      end
    end
  end

  describe '#tmp_path_for' do
    context 'passing config' do
      subject { described_class.tmp_path_for(config:, store_name: 'giraffes') }

      def gen_hash(path)
        Digest::SHA1.hexdigest(File.absolute_path(path))[0..12]
      end

      let(:code_snippets) { [] }
      let(:items) { [] }
      let(:layouts) { [] }

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

  it 'deletes and reloads on error' do
    store = test_store_klass.new('test', 1)

    # Create
    store.load
    store.data = { fun: 'sure' }
    store.store

    # Test stored values
    store = test_store_klass.new('test', 1)
    store.load
    expect(store.data).to eq(fun: 'sure')

    # Mess up
    File.write('test.data.db', 'Damn {}#}%@}$^)@&$&*^#@ broken stores!!!')

    # Reload
    store = test_store_klass.new('test', 1)
    store.load
    expect(store.data).to be_nil
  end

  it 'can write humongous amounts of data' do
    # Skip running on GitHub actions etc because this thing just uses far too many resources
    skip 'GitHub Actions does not give us enough resources to run this' if ENV['CI']

    store = test_store_klass.new('test', 1)

    # Create huge string
    array = []
    100.times do |i|
      raw = 'x' * 1_000_037
      raw << i.to_s
      io = StringIO.new
      100.times { io << raw }
      array << io.string
    end

    # Write
    store.data = { data: array }
    expect { store.store }.not_to raise_exception
  end
end
