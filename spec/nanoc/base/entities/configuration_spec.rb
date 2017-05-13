describe Nanoc::Int::Configuration do
  let(:hash) { { foo: 'bar' } }
  let(:config) { described_class.new(hash: hash) }

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
      let(:config) { described_class.new(hash: hash, env_name: 'giraffes') }

      it 'retains the env name' do
        expect(subject.env_name).to eql('giraffes')
      end
    end
  end

  describe '#output_dir' do
    subject { config.with_defaults.output_dir }

    context 'not explicitly defined' do
      let(:hash) { { foo: 'bar' } }
      it { is_expected.to eql('output') }
    end

    context 'explicitly defined, top-level' do
      let(:hash) { { foo: 'bar', output_dir: 'build' } }
      it { is_expected.to eql('build') }
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
      expect(subject).to include('output_toplevel')
      expect(subject).to include('output_default')
    end

    it 'does not contain nil' do
      expect(subject).not_to include(nil)
    end

    it 'contains all other output dirs' do
      expect(subject).to include('output_staging')
      expect(subject).to include('output_prod')
    end
  end

  describe '#merge' do
    let(:hash1) { { foo: { bar: 'baz', baz: ['biz'] } } }
    let(:hash2) { { foo: { bar: :boz, biz: 'buz' } } }
    let(:config1) { described_class.new(hash: hash1) }
    let(:config2) { described_class.new(hash: hash2) }

    subject { config1.merge(config2).to_h }

    it 'contains the recursive merge of both configurations' do
      expect(subject).to include(foo: { bar: :boz, baz: ['biz'], biz: 'buz' })
    end
  end

  context 'with environments defined' do
    let(:hash) { { foo: 'bar', environments: { test: { foo: 'test-bar' }, default: { foo: 'default-bar' } } } }
    let(:config) { described_class.new(hash: hash, env_name: env_name).with_environment }

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
end
