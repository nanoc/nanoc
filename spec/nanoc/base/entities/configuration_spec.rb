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
