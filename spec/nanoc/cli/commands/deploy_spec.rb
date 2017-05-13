# frozen_string_literal: true

describe Nanoc::CLI::Commands::Deploy, site: true, stdio: true do
  describe '#run' do
    let(:config) { {} }

    before do
      # Prevent double-loading
      expect(Nanoc::CLI).to receive(:setup)

      File.write('nanoc.yaml', YAML.dump(config))
    end

    shared_examples 'no effective deploy' do
      it 'does not write any files' do
        expect { run rescue nil }.not_to change { Dir['remote/*'] }
        expect(Dir['remote/*']).to be_empty
      end
    end

    shared_examples 'effective deploy' do
      it 'writes files' do
        expect { run }.to change { Dir['remote/*'] }.from([]).to(['remote/success.txt'])
        expect(File.read('remote/success.txt')).to eql('hurrah')
      end
    end

    shared_examples 'attempted/effective deploy' do
      context 'no checks' do
        include_examples 'effective deploy'
      end

      context 'checks fail' do
        before do
          File.write(
            'Checks',
            "check :donkey do\n" \
            "  add_issue('things are broken', subject: 'success.txt')\n" \
            "end\n" \
            "\n" \
            "deploy_check :donkey\n",
          )
        end

        include_examples 'no effective deploy'

        context 'checks disabled' do
          context '--no-check' do
            let(:command) { super() + ['--no-check'] }
            include_examples 'effective deploy'
          end

          context '--Ck' do
            let(:command) { super() + ['-C'] }
            include_examples 'effective deploy'
          end
        end
      end

      context 'checks pass' do
        before do
          File.write(
            'Checks',
            "check :donkey do\n" \
            "end\n" \
            "\n" \
            "deploy_check :donkey\n",
          )
        end

        include_examples 'effective deploy'
      end
    end

    describe 'listing deployers' do
      shared_examples 'lists all deployers' do
        let(:run) { Nanoc::CLI.run(command) }

        it 'lists all deployers' do
          expect { run }.to output(/Available deployers:\n  fog\n  git\n  rsync/).to_stdout
        end

        include_examples 'no effective deploy'
      end

      context '--list-deployers' do
        let(:command) { %w[deploy --list-deployers] }
        include_examples 'lists all deployers'
      end

      context '-D' do
        let(:command) { %w[deploy -D] }
        include_examples 'lists all deployers'
      end
    end

    describe 'listing deployment configurations' do
      shared_examples 'lists all deployment configurations' do
        let(:run) { Nanoc::CLI.run(command) }

        context 'no deployment configurations' do
          let(:config) { { donkeys: 'lots' } }

          it 'says nothing is found' do
            expect { run }.to output(/No deployment configurations./).to_stdout
          end

          include_examples 'no effective deploy'
        end

        context 'some deployment configurations' do
          let(:config) do
            {
              deploy: {
                production: {
                  kind: 'rsync',
                  dst: 'remote',
                },
                staging: {
                  kind: 'rsync',
                  dst: 'remote',
                },
              },
            }
          end

          it 'says some targets are found' do
            expect { run }.to output(/Available deployment configurations:\n  production\n  staging/).to_stdout
          end

          include_examples 'no effective deploy'
        end
      end

      context '--list' do
        let(:command) { %w[deploy --list] }
        include_examples 'lists all deployment configurations'
      end

      context '-L' do
        let(:command) { %w[deploy -L] }
        include_examples 'lists all deployment configurations'
      end
    end

    describe 'deploying' do
      let(:run) { Nanoc::CLI.run(command) }
      let(:command) { %w[deploy] }

      before do
        FileUtils.mkdir_p('output')
        FileUtils.mkdir_p('remote')
        File.write('output/success.txt', 'hurrah')
      end

      shared_examples 'missing kind warning' do
        it 'warns about missing kind' do
          expect { run }.to output(/Warning: The specified deploy target does not have a kind attribute. Assuming rsync./).to_stderr
        end
      end

      context 'no deploy configs' do
        it 'errors' do
          expect { run }.to raise_error(
            Nanoc::Int::Errors::GenericTrivial,
            'The site has no deployment configurations.',
          )
        end

        include_examples 'no effective deploy'

        context 'configuration created in preprocessor' do
          before do
            File.write(
              'Rules',
              "preprocess do\n" \
              "  @config[:deploy] = {\n" \
              "    default: { dst: 'remote' },\n" \
              "  }\n" \
              "end\n\n" + File.read('Rules'),
            )
          end

          include_examples 'attempted/effective deploy'
        end
      end

      context 'some deploy configs' do
        let(:config) do
          {
            deploy: {
              irrelevant: {
                kind: 'rsync',
                dst: 'remote',
              },
            },
          }
        end

        context 'default target' do
          context 'requested deploy config does not exist' do
            it 'errors' do
              expect { run }.to raise_error(
                Nanoc::Int::Errors::GenericTrivial,
                'The site has no deployment configuration named `default`.',
              )
            end

            include_examples 'no effective deploy'
          end

          context 'requested deploy config exists' do
            let(:config) do
              {
                deploy: {
                  default: {
                    kind: 'rsync',
                    dst: 'remote',
                  },
                },
              }
            end

            include_examples 'attempted/effective deploy'

            context 'dry run' do
              let(:command) { super() + ['--dry-run'] }
              include_examples 'no effective deploy'
            end
          end

          context 'requested deploy config exists, but has no kind' do
            let(:config) do
              {
                deploy: {
                  default: {
                    dst: 'remote',
                  },
                },
              }
            end

            include_examples 'attempted/effective deploy'
            include_examples 'missing kind warning'

            context 'dry run' do
              let(:command) { super() + ['--dry-run'] }
              include_examples 'no effective deploy'
            end
          end
        end

        shared_examples 'deploy with non-default target' do
          context 'requested deploy config does not exist' do
            it 'errors' do
              expect { run }.to raise_error(
                Nanoc::Int::Errors::GenericTrivial,
                'The site has no deployment configuration named `production`.',
              )
            end

            include_examples 'no effective deploy'
          end

          context 'requested deploy config exists' do
            let(:config) do
              {
                deploy: {
                  production: {
                    kind: 'rsync',
                    dst: 'remote',
                  },
                },
              }
            end

            include_examples 'attempted/effective deploy'

            context 'dry run' do
              let(:command) { (super() + ['--dry-run']) }
              include_examples 'no effective deploy'
            end
          end

          context 'requested deploy config exists, but has no kind' do
            let(:config) do
              {
                deploy: {
                  production: {
                    dst: 'remote',
                  },
                },
              }
            end

            include_examples 'attempted/effective deploy'
            include_examples 'missing kind warning'

            context 'dry run' do
              let(:command) { (super() + ['--dry-run']) }
              include_examples 'no effective deploy'
            end
          end
        end

        context 'non-default target, specified as argument' do
          let(:command) { %w[deploy production] }
          include_examples 'deploy with non-default target'
        end

        context 'non-default target, specified as option (--target)' do
          let(:command) { %w[deploy --target production] }
          include_examples 'deploy with non-default target'
        end

        context 'multiple targets specified' do
          let(:command) { %w[deploy --target staging production] }

          it 'errors' do
            expect { run }.to raise_error(
              Nanoc::Int::Errors::GenericTrivial,
              'Only one deployment target can be specified on the command line.',
            )
          end
        end
      end
    end
  end
end
