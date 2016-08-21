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
