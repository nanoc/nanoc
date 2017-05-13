# frozen_string_literal: true

describe Nanoc::Deploying::Deployers::Git, stdio: true do
  let(:deployer) { described_class.new(output_dir, options, dry_run: dry_run) }

  subject { deployer.run }

  let(:output_dir) { 'output/' }
  let(:options) { remote_options.merge(branch_options).merge(forced_options) }
  let(:dry_run) { false }

  let(:remote_options) { {} }
  let(:branch_options) { {} }
  let(:forced_options) { {} }

  def run_and_get_stdout(*args)
    stdout = String.new
    stderr = String.new
    piper = Nanoc::Extra::Piper.new(stdout: stdout, stderr: stderr)
    piper.run(args, '')
    stdout
  end

  def add_changes_to_remote
    system('git', 'init', '--quiet', 'rere_tmp')
    Dir.chdir('rere_tmp') do
      system('git', 'config', 'user.name', 'Zebra Platypus')
      system('git', 'config', 'user.email', 'zebra@platypus.example.com')
      system('git', 'remote', 'add', 'origin', '../rere')

      File.write('evil.txt', 'muaha')
      system('git', 'add', 'evil.txt')
      system('git', 'commit', '--quiet', '-m', 'muaha')
      system('git', 'checkout', '--quiet', '-b', 'giraffe')
      system('git', 'push', '--quiet', 'origin', 'master')
      system('git', 'push', '--quiet', 'origin', 'giraffe')
    end
  end

  def rev_list
    run_and_get_stdout('git', 'rev-list', '--objects', '--all')
  end

  shared_examples 'branch configured properly' do
    context 'clean working copy' do
      it 'does not commit or push' do
        subject
      end
    end

    context 'non-clean working copy' do
      before do
        Dir.chdir(output_dir) { File.write('hello.txt', 'Hi there') }
      end

      shared_examples 'successful push' do
        context 'no dry run' do
          it 'outputs status' do
            expect { subject }
              .to output(/Deploying via Git to branch “#{branch}” on remote “#{remote}”…/)
              .to_stdout
          end

          it 'makes a change in the local repo' do
            expect { subject }
              .to change { Dir.chdir(output_dir) { rev_list } }
              .from(not_match(/^[a-f0-9]{40} hello\.txt$/))
              .to(match(/^[a-f0-9]{40} hello\.txt$/))

            expect(Dir.chdir(output_dir) { run_and_get_stdout('git', 'show', branch) })
              .to match(/^Author: Nanoc <>$/)
          end

          it 'makes a change in the remote repo' do
            expect { subject }
              .to change { Dir.chdir('rere') { rev_list } }
              .from(not_match(/^[a-f0-9]{40} hello\.txt$/))
              .to(match(/^[a-f0-9]{40} hello\.txt$/))
          end
        end

        context 'dry run' do
          let(:dry_run) { true }

          it 'makes a change in the local repo' do
            expect { subject }
              .not_to change { Dir.chdir(output_dir) { rev_list } }
          end

          it 'makes a change in the remote repo' do
            expect { subject }
              .not_to change { Dir.chdir('rere') { rev_list } }
          end
        end
      end

      context 'forced' do
        let(:forced_options) { { forced: true } }

        context 'remote has no other changes' do
          include_examples 'successful push'
        end

        context 'remote has other changes' do
          before { add_changes_to_remote }
          include_examples 'successful push'
        end
      end

      context 'not forced (implicit)' do
        let(:forced_options) { {} }

        context 'remote has no other changes' do
          include_examples 'successful push'
        end

        context 'remote has other changes' do
          before { add_changes_to_remote }

          it 'raises' do
            expect { subject }.to raise_error(Nanoc::Extra::Piper::Error)
          end
        end
      end

      context 'not forced (explicit)' do
        let(:forced_options) { { forced: false } }

        context 'remote has no other changes' do
          include_examples 'successful push'
        end

        context 'remote has other changes' do
          before { add_changes_to_remote }

          it 'raises' do
            expect { subject }.to raise_error(Nanoc::Extra::Piper::Error)
          end
        end
      end
    end
  end

  shared_examples 'remote configured properly' do
    before do
      system('git', 'init', '--bare', '--quiet', 'rere')
    end

    context 'default branch' do
      context 'branch does not exist' do
        it 'raises' do
          expect { subject }.to raise_error(
            Nanoc::Deploying::Deployers::Git::Errors::BranchDoesNotExist,
            'The branch to deploy, master, does not exist.',
          )
        end
      end

      context 'branch exists' do
        before do
          Dir.chdir(output_dir) do
            system('git', 'commit', '--quiet', '-m', 'init', '--allow-empty')
          end
        end

        let(:branch) { 'master' }

        include_examples 'branch configured properly'
      end
    end

    context 'custom branch' do
      let(:branch) { 'giraffe' }
      let(:branch_options) { { branch: branch } }

      context 'branch does not exist' do
        it 'raises' do
          expect { subject }.to raise_error(
            Nanoc::Deploying::Deployers::Git::Errors::BranchDoesNotExist,
            'The branch to deploy, giraffe, does not exist.',
          )
        end
      end

      context 'branch exists' do
        before do
          Dir.chdir(output_dir) do
            system('git', 'commit', '--quiet', '-m', 'init', '--allow-empty')
            system('git', 'branch', 'giraffe')
          end
        end

        include_examples 'branch configured properly'
      end
    end
  end

  context 'output dir does not exist' do
    it 'raises' do
      expect { subject }.to raise_error(
        Nanoc::Deploying::Deployers::Git::Errors::OutputDirDoesNotExist,
        'The directory to deploy, output/, does not exist.',
      )
    end
  end

  context 'output dir exists' do
    before do
      FileUtils.mkdir_p(output_dir)
    end

    context 'output dir is not a Git repo' do
      it 'raises' do
        expect { subject }.to raise_error(
          Nanoc::Deploying::Deployers::Git::Errors::OutputDirIsNotAGitRepo,
          'The directory to deploy, output/, is not a Git repository.',
        )
      end
    end

    context 'output dir is a Git repo' do
      before do
        Dir.chdir(output_dir) do
          system('git', 'init', '--quiet')
          system('git', 'config', 'user.name', 'Donkey Giraffe')
          system('git', 'config', 'user.email', 'donkey@giraffe.example.com')
        end
      end

      context 'default remote' do
        context 'remote does not exist' do
          it 'raises' do
            expect { subject }.to raise_error(
              Nanoc::Deploying::Deployers::Git::Errors::RemoteDoesNotExist,
              'The remote to deploy to, origin, does not exist.',
            )
          end
        end

        context 'remote exists' do
          before do
            Dir.chdir(output_dir) do
              system('git', 'remote', 'add', 'origin', '../rere')
            end
          end

          let(:remote) { 'origin' }

          include_examples 'remote configured properly'
        end
      end

      context 'custom remote (name)' do
        let(:remote_options) { { remote: 'donkey' } }

        context 'remote does not exist' do
          it 'raises' do
            expect { subject }.to raise_error(
              Nanoc::Deploying::Deployers::Git::Errors::RemoteDoesNotExist,
              'The remote to deploy to, donkey, does not exist.',
            )
          end
        end

        context 'remote exists' do
          before do
            Dir.chdir(output_dir) do
              system('git', 'remote', 'add', 'donkey', '../rere')
            end
          end

          let(:remote) { 'donkey' }

          include_examples 'remote configured properly'
        end
      end

      context 'custom remote (file:// URL)' do
        let(:remote_options) { { remote: remote } }

        let(:remote) { "file://#{Dir.getwd}/rere" }

        include_examples 'remote configured properly'
      end
    end
  end

  describe '#remote_is_name?' do
    def val(remote)
      deployer.send(:remote_is_name?, remote)
    end

    it 'recognises names' do
      expect(val('denis')).to be
    end

    it 'recognises URLs' do
      expect(val('git@github.com:/foo')).not_to be
      expect(val('http://example.com/donkey.git')).not_to be
      expect(val('https://example.com/donkey.git')).not_to be
      expect(val('ssh://example.com/donkey.git')).not_to be
      expect(val('file:///example.com/donkey.git')).not_to be
    end
  end
end
