# frozen_string_literal: true

describe Nanoc::Deploying::Deployers::Fog, stdio: true do
  subject { deployer.run }

  let(:deployer) do
    described_class.new(
      'output/',
      config,
      dry_run: is_dry_run,
    )
  end

  let(:is_dry_run) { false }

  let(:config) do
    {
      bucket: 'bucky',
      provider:,
      local_root: 'remote',
    }
  end

  let(:provider) { 'local' }

  before do
    skip_unless_gem_available('fog/core')

    # create output
    FileUtils.mkdir_p('output')
    FileUtils.mkdir_p('output/etc')
    File.write('output/woof', 'I am a dog!')
    File.write('output/etc/meow', 'I am a cat!')

    # create local cloud
    FileUtils.mkdir_p('remote')
  end

  shared_examples 'no effective deploy' do
    it 'does not modify remote' do
      expect { subject }.not_to change { Dir['remote/**/*'].sort }
    end
  end

  shared_examples 'effective deploy' do
    it 'modifies remote' do
      expect { subject }.to change { Dir['remote/**/*'].sort }
        .to([
          'remote/bucky',
          'remote/bucky/etc',
          'remote/bucky/etc/meow',
          'remote/bucky/woof',
        ])
    end
  end

  context 'dry run' do
    let(:is_dry_run) { true }

    before do
      FileUtils.mkdir_p('remote/bucky')
      FileUtils.mkdir_p('remote/bucky/tiny')
      File.write('remote/bucky/pig', 'oink?')
      File.write('remote/bucky/tiny/piglet', 'little oink?')
    end

    include_examples 'no effective deploy'

    context 'with CDN ID' do
      let(:config) { super().merge(cdn_id: 'donkey-cdn') }

      let(:cdn) { Object.new }
      let(:distribution) { Object.new }

      it 'does not actually invalidate' do
        expect(Fog::CDN).to receive(:new).with({ provider: 'local', local_root: 'remote' }).and_return(cdn)
        expect(cdn).to receive(:get_distribution).with('donkey-cdn').and_return(distribution)

        subject
      end
    end
  end

  context 'effective run' do
    include_examples 'effective deploy'

    context 'custom path' do
      context 'custom path ends with /' do
        let(:config) do
          super().merge(path: 'foo/')
        end

        it 'raises' do
          expect { subject }.to raise_error('The path `foo/` is not supposed to have a trailing slash')
        end
      end

      context 'custom path does not end with /' do
        let(:config) do
          super().merge(path: 'foo')
        end

        it 'modifies remote' do
          expect { subject }.to change { Dir['remote/**/*'].sort }
            .to([
              'remote/bucky',
              'remote/bucky/foo',
              'remote/bucky/foo/etc',
              'remote/bucky/foo/etc/meow',
              'remote/bucky/foo/woof',
            ])
        end
      end
    end

    context 'bucket already exists' do
      before do
        FileUtils.mkdir_p('remote/bucky')
      end

      include_examples 'effective deploy'
    end

    context 'remote contains stale file at root' do
      before do
        FileUtils.mkdir_p('remote/bucky')
        File.write('remote/bucky/pig', 'oink?')
      end

      include_examples 'effective deploy'

      it 'does not contain stale files' do
        subject
        expect(Dir['remote/**/*'].sort).not_to include('remote/bucky/pig')
      end
    end

    context 'remote contains stale file in subdirectory' do
      before do
        FileUtils.mkdir_p('remote/bucky/secret')
        File.write('remote/bucky/secret/pig', 'oink?')
      end

      include_examples 'effective deploy'

      it 'does not contain stale files' do
        subject
        expect(Dir['remote/**/*'].sort).not_to include('remote/bucky/secret/pig')
      end
    end

    context 'with CDN ID' do
      let(:config) { super().merge(cdn_id: 'donkey-cdn') }

      let(:cdn) { Object.new }
      let(:distribution) { Object.new }

      it 'invalidates' do
        expect(Fog::CDN).to receive(:new).with({ provider: 'local', local_root: 'remote' }).and_return(cdn)
        expect(cdn).to receive(:get_distribution).with('donkey-cdn').and_return(distribution)
        expect(cdn).to receive(:post_invalidation).with(distribution, contain_exactly('etc/meow', 'woof'))

        subject
      end
    end

    context 'remote list consists of truncated sets' do
      before do
        expect(Fog::Storage).to receive(:new).and_return(fog_storage)
        expect(fog_storage).to receive(:directories).and_return(directories)
        expect(directories).to receive(:get).and_return(directory)
        allow(directory).to receive(:files).and_return(files)
        expect(files).to receive(:get).with('stray').and_return(file_stray).ordered
        expect(files).to receive(:each)
          .and_yield(double(:woof, key: 'woof'))
          .and_yield(double(:meow, key: 'etc/meow'))
          .and_yield(double(:stray, key: 'stray'))
        expect(file_stray).to receive(:destroy)

        expect(files).to receive(:create).with(key: 'woof', body: anything, public: true) do
          FileUtils.mkdir_p('remote/bucky')
          File.write('remote/bucky/woof', 'hi')
        end
        expect(files).to receive(:create).with(key: 'etc/meow', body: anything, public: true) do
          FileUtils.mkdir_p('remote/bucky/etc')
          File.write('remote/bucky/etc/meow', 'hi')
        end
      end

      let(:fog_storage) { double(:fog_storage) }
      let(:directories) { double(:directories) }
      let(:directory) { double(:directory) }
      let(:files) { double(:files) }
      let(:file_stray) { double(:file_stray) }

      include_examples 'effective deploy'
    end
  end

  describe '#read_etags' do
    subject { deployer.send(:read_etags, files) }

    context 'when using local provider' do
      let(:provider) { 'local' }

      let(:files) do
        [
          double('file_a'),
          double('file_b'),
        ]
      end

      it { is_expected.to eq({}) }
    end

    context 'when using aws provider' do
      let(:provider) { 'aws' }

      let(:files) do
        [
          double('file_a', key: 'key_a', etag: 'etag_a'),
          double('file_b', key: 'key_b', etag: 'etag_b'),
        ]
      end

      let(:expected) do
        {
          'key_a' => 'etag_a',
          'key_b' => 'etag_b',
        }
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#calc_local_etag' do
    subject { deployer.send(:calc_local_etag, file_path) }

    let(:file_path) { 'blah.tmp' }

    before do
      File.write(file_path, 'hallo')
    end

    context 'when using local provider' do
      let(:provider) { 'local' }

      it { is_expected.to be_nil }
    end

    context 'when using aws provider' do
      let(:provider) { 'aws' }

      it { is_expected.to eq('598d4c200461b81522a3328565c25f7c') }
    end
  end

  describe '#needs_upload?' do
    subject { deployer.send(:needs_upload?, key, file_path, etags) }

    let(:file_path) { 'blah.tmp' }
    let(:key) { '/moo/remote/blah.tmp.123' }
    let(:provider) { 'aws' }

    before do
      File.write(file_path, 'hallo')
    end

    context 'missing remote etag' do
      let(:etags) { {} }

      it { is_expected.to be true }
    end

    context 'different etags' do
      let(:etags) { { key => 'some-other-etag' } }

      it { is_expected.to be true }
    end

    context 'identical etags' do
      let(:etags) { { key => '598d4c200461b81522a3328565c25f7c' } }

      it { is_expected.to be false }
    end
  end
end
