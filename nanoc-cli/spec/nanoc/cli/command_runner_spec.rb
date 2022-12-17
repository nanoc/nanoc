# frozen_string_literal: true

describe Nanoc::CLI::CommandRunner, stdio: true do
  describe '.find_site_dir' do
    subject { described_class.find_site_dir }

    context 'config file in current dir' do
      before { File.write('nanoc.yaml', 'hi') }

      it 'returns the current dir' do
        expect(subject).to eq(File.expand_path(Dir.getwd))
      end
    end

    context 'config file in parent dir' do
      around do |ex|
        FileUtils.mkdir_p('root/sub')
        File.write('root/nanoc.yaml', 'hi')
        chdir('root/sub') { ex.run }
      end

      it 'returns the parent dir' do
        expect(subject).to match(/root$/)
      end
    end

    context 'config file in grandparent dir' do
      around do |ex|
        FileUtils.mkdir_p('root/sub1/sub2')
        File.write('root/nanoc.yaml', 'hi')
        chdir('root/sub1/sub2') { ex.run }
      end

      it 'returns the parent dir' do
        expect(subject).to match(/root$/)
      end
    end

    context 'no config file in ancestral paths' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '.enter_site_dir' do
    subject do
      described_class.enter_site_dir
      Dir.getwd
    end

    context 'config file in current dir' do
      before { File.write('nanoc.yaml', 'hi') }

      it 'returns the current dir' do
        expect(subject).to eq(File.expand_path(Dir.getwd))
      end
    end

    context 'config file in parent dir' do
      around do |ex|
        FileUtils.mkdir_p('root/sub')
        File.write('root/nanoc.yaml', 'hi')
        chdir('root/sub') { ex.run }
      end

      it 'returns the parent dir' do
        expect(subject).to match(/root$/)
      end
    end

    context 'config file in grandparent dir' do
      around do |ex|
        FileUtils.mkdir_p('root/sub1/sub2')
        File.write('root/nanoc.yaml', 'hi')
        chdir('root/sub1/sub2') { ex.run }
      end

      it 'enters the parent dir' do
        expect(subject).to match(/root$/)
      end
    end

    context 'no config file in ancestral paths' do
      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Core::TrivialError, 'The current working directory, nor any of its parents, seems to be a Nanoc site.')
      end
    end
  end

  describe '#load_site' do
    subject { command_runner.load_site }

    let(:command_runner) { described_class.new(nil, nil, nil) }

    before { File.write('nanoc.yaml', '{}') }

    it 'does not set @site' do
      expect(command_runner.instance_variable_get(:@site)).to be_nil
      expect { subject }.not_to change { command_runner.instance_variable_get(:@site) }
    end

    it 'returns site' do
      expect(subject).to be_a(Nanoc::Core::Site)
    end
  end
end
