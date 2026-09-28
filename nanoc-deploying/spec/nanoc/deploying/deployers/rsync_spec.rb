# frozen_string_literal: true

describe Nanoc::Deploying::Deployers::Rsync, :stdio do
  subject { deployer.run }

  let(:deployer) do
    described_class.new(
      'output',
      config,
      **extra_opts,
    )
  end

  let(:config) { {} }
  let(:extra_opts) { {} }

  before do
    skip_unless_have_command 'rsync'

    # create output
    FileUtils.mkdir_p('output')
    FileUtils.mkdir_p('output/etc')
    File.write('output/woof', 'I am a dog!')
    File.write('output/etc/meow', 'I am a cat!')

    # create local cloud
    FileUtils.mkdir_p('remote')
  end

  context 'destination is missing' do
    let(:config) { {} }

    it 'raises' do
      expect { subject }.to raise_error(RuntimeError, 'No dst found in deployment configuration')
    end
  end

  context 'destination is incorrect' do
    let(:config) { { dst: 'asdf/' } }

    it 'raises' do
      expect { subject }.to raise_error(RuntimeError, 'dst requires no trailing slash')
    end
  end

  context 'destination is correct' do
    let(:dst_dir) { Dir.mktmpdir('nanoc-rsync-test') }
    let(:config) { { dst: dst_dir } }

    context 'dry run' do
      let(:extra_opts) { { dry_run: true } }

      it 'writes output' do
        expect { deployer.run }.to output(%r{^etc/meow$}).to_stdout
      end

      it 'does not copy files' do
        deployer.run

        expect(File.file?("#{dst_dir}/woof")).to be(false)
        expect(File.file?("#{dst_dir}/etc/meow")).to be(false)
      end
    end

    context 'actual run' do
      it 'copies files' do
        deployer.run

        expect(File.file?("#{dst_dir}/woof")).to be(true)
        expect(File.read("#{dst_dir}/woof")).to eq('I am a dog!')
        expect(File.file?("#{dst_dir}/etc/meow")).to be(true)
        expect(File.read("#{dst_dir}/etc/meow")).to eq('I am a cat!')
      end

      it 'writes output' do
        expect { deployer.run }.to output(%r{^etc/meow$}).to_stdout
      end

      it 'does not copy .git' do
        FileUtils.mkdir_p('output/.git')
        File.write('output/.git/HEAD', 'The head!')

        deployer.run

        expect(File.file?("#{dst_dir}/woof")).to be(true)
        expect(File.read("#{dst_dir}/woof")).to eq('I am a dog!')
        expect(File.file?("#{dst_dir}/etc/meow")).to be(true)
        expect(File.read("#{dst_dir}/etc/meow")).to eq('I am a cat!')
        expect(File.file?("#{dst_dir}/.git/HEAD")).to be(false)
      end
    end
  end
end
