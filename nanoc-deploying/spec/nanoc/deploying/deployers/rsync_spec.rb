# frozen_string_literal: true

describe Nanoc::Deploying::Deployers::Rsync, stdio: true do
  subject { deployer.run }

  let(:deployer) do
    described_class.new(
      'output',
      config,
      extra_opts,
    )
  end

  let(:config) { {} }
  let(:extra_opts) { {} }

  before do
    skip_unless_have_command 'rsync'

    # create output
    FileUtils.mkdir_p('output')
    FileUtils.mkdir_p('output/etc')
    File.open('output/woof', 'w') { |io| io.write 'I am a dog!' }
    File.open('output/etc/meow', 'w') { |io| io.write 'I am a cat!' }

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
    let(:config) { { dst: 'asdf' } }

    context 'dry run' do
      let(:extra_opts) { { dry_run: true } }

      it 'runs' do
        opts = Nanoc::Deploying::Deployers::Rsync::DEFAULT_OPTIONS
        args = ['echo', 'rsync', opts, 'output/', 'asdf'].flatten
        expect(deployer).to receive(:run_shell_cmd).with(args)

        deployer.run
      end
    end

    context 'actual run' do
      it 'runs' do
        opts = Nanoc::Deploying::Deployers::Rsync::DEFAULT_OPTIONS
        args = ['rsync', opts, 'output/', 'asdf'].flatten
        expect(deployer).to receive(:run_shell_cmd).with(args)

        deployer.run
      end
    end
  end
end
