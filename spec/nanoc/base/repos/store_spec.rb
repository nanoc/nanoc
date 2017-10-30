# frozen_string_literal: true

describe Nanoc::Int::Store do
  describe '#tmp_path_for' do
    context 'passing site' do
      subject { described_class.tmp_path_for(site: site, store_name: 'giraffes') }

      let(:site) do
        Nanoc::Int::Site.new(
          config: config,
          code_snippets: code_snippets,
          data_source: Nanoc::Int::InMemDataSource.new(items, layouts),
        )
      end

      let(:code_snippets) { [] }
      let(:items) { [] }
      let(:layouts) { [] }

      context 'no env specified' do
        let(:config) { Nanoc::Int::Configuration.new(hash: config_hash).with_defaults.with_environment }

        context 'output dir at root is specified' do
          let(:config_hash) { { output_dir: 'output-default' } }
          it { is_expected.to eql('tmp/nanoc/b592240c777c6/giraffes') }
        end

        context 'output dir in default env is specified' do
          let(:config_hash) { { environments: { default: { output_dir: 'output-default' } } } }
          it { is_expected.to eql('tmp/nanoc/b592240c777c6/giraffes') }
        end

        context 'output dir in other env is specified' do
          let(:config_hash) { { environments: { production: { output_dir: 'output-production' } } } }
          it { is_expected.to eql('tmp/nanoc/1029d67644815/giraffes') }
        end
      end

      context 'env specified' do
        let(:config) { Nanoc::Int::Configuration.new(env_name: 'staging', hash: config_hash).with_defaults.with_environment }

        context 'output dir at root is specified' do
          let(:config_hash) { { output_dir: 'output-default' } }
          it { is_expected.to eql('tmp/nanoc/b592240c777c6/giraffes') }
        end

        context 'output dir in given env is specified' do
          let(:config_hash) { { environments: { staging: { output_dir: 'output-staging' } } } }
          it { is_expected.to eql('tmp/nanoc/9d274da4d73ba/giraffes') }
        end

        context 'output dir in other env is specified' do
          let(:config_hash) { { environments: { production: { output_dir: 'output-production' } } } }
          it { is_expected.to eql('tmp/nanoc/1029d67644815/giraffes') }
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
