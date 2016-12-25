describe Nanoc::Int::ItemRep do
  let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo.md') }
  let(:rep) { Nanoc::Int::ItemRep.new(item, :giraffe) }

  describe '#compiled_content' do
    let(:snapshot_name) { raise 'override me' }
    subject { rep.compiled_content(snapshot: snapshot_name) }

    shared_examples 'a non-moving snapshot with content' do
      context 'no snapshot def' do
        it 'raises' do
          expect { subject }.to raise_error(Nanoc::Int::Errors::NoSuchSnapshot)
        end
      end

      context 'snapshot def exists' do
        before do
          rep.snapshot_defs = [Nanoc::Int::SnapshotDef.new(snapshot_name)]
          rep.snapshot_contents = { snapshot_name => content }
        end

        context 'content is textual' do
          let(:content) { Nanoc::Int::TextualContent.new('hellos') }
          it { is_expected.to eql('hellos') }
        end

        context 'content is binary' do
          before { File.write('donkey.dat', 'binary data') }
          let(:content) { Nanoc::Int::BinaryContent.new(File.expand_path('donkey.dat')) }

          it 'raises' do
            expect { subject }.to raise_error(Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem)
          end
        end
      end
    end

    shared_examples 'a non-moving snapshot' do
      include_examples 'a non-moving snapshot with content'

      context 'snapshot def exists, but not content' do
        before do
          rep.snapshot_defs = [Nanoc::Int::SnapshotDef.new(snapshot_name)]
          rep.snapshot_contents = {}
        end

        it 'errors' do
          expect { subject }.to yield_from_fiber(an_instance_of(Nanoc::Int::Errors::UnmetDependency))
        end
      end
    end

    shared_examples 'snapshot :last' do
      context 'no snapshot def' do
        it 'errors' do
          expect { subject }.to raise_error(Nanoc::Int::Errors::NoSuchSnapshot)
        end
      end

      context 'snapshot exists' do
        context 'snapshot is not final' do
          before do
            rep.snapshot_defs = [Nanoc::Int::SnapshotDef.new(snapshot_name)]
          end

          context 'snapshot content does not exist' do
            before do
              rep.snapshot_contents = {}
            end

            it 'errors' do
              expect { subject }.to yield_from_fiber(an_instance_of(Nanoc::Int::Errors::UnmetDependency))
            end
          end

          context 'snapshot content exists' do
            context 'content is textual' do
              before do
                rep.snapshot_contents[snapshot_name] = Nanoc::Int::TextualContent.new('hellos')
              end

              context 'not compiled' do
                before { rep.compiled = false }

                it 'raises' do
                  expect { subject }.to yield_from_fiber(an_instance_of(Nanoc::Int::Errors::UnmetDependency))
                end
              end

              context 'compiled' do
                before { rep.compiled = true }

                it { is_expected.to eql('hellos') }
              end
            end

            context 'content is binary' do
              before do
                File.write('donkey.dat', 'binary data')
                rep.snapshot_contents[snapshot_name] = Nanoc::Int::BinaryContent.new(File.expand_path('donkey.dat'))
              end

              context 'not compiled' do
                before { rep.compiled = false }

                it 'raises' do
                  expect { subject }.to yield_from_fiber(an_instance_of(Nanoc::Int::Errors::UnmetDependency))
                end
              end

              context 'compiled' do
                before { rep.compiled = true }

                it 'raises' do
                  expect { subject }.to raise_error(Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem)
                end
              end
            end
          end
        end

        context 'snapshot is final' do
          before do
            rep.snapshot_defs = [Nanoc::Int::SnapshotDef.new(snapshot_name)]
          end

          context 'snapshot content does not exist' do
            before do
              rep.snapshot_contents = {}
            end

            it 'errors' do
              expect { subject }.to yield_from_fiber(an_instance_of(Nanoc::Int::Errors::UnmetDependency))
            end
          end

          context 'snapshot content exists' do
            context 'content is textual' do
              before do
                rep.snapshot_contents[snapshot_name] = Nanoc::Int::TextualContent.new('hellos')
              end

              context 'not compiled' do
                before { rep.compiled = false }

                it 'errors' do
                  expect { subject }.to yield_from_fiber(an_instance_of(Nanoc::Int::Errors::UnmetDependency))
                end
              end

              context 'compiled' do
                before { rep.compiled = true }

                it { is_expected.to eql('hellos') }
              end
            end

            context 'content is binary' do
              before do
                File.write('donkey.dat', 'binary data')
                rep.snapshot_contents[snapshot_name] = Nanoc::Int::BinaryContent.new(File.expand_path('donkey.dat'))
              end

              context 'not compiled' do
                before { rep.compiled = false }

                it 'raises' do
                  expect { subject }.to yield_from_fiber(an_instance_of(Nanoc::Int::Errors::UnmetDependency))
                end
              end

              context 'compiled' do
                before { rep.compiled = true }

                it 'raises' do
                  expect { subject }.to raise_error(Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem)
                end
              end
            end
          end
        end
      end
    end

    context 'snapshot nil' do
      let(:snapshot_name) { :last }
      subject { rep.compiled_content(snapshot: nil) }
      include_examples 'snapshot :last'
    end

    context 'snapshot not specified' do
      subject { rep.compiled_content }

      context 'pre exists' do
        before { rep.snapshot_contents[:pre] = Nanoc::Int::TextualContent.new('omg') }
        let(:snapshot_name) { :pre }
        include_examples 'a non-moving snapshot with content'
      end

      context 'pre does not exist' do
        let(:snapshot_name) { :last }
        include_examples 'snapshot :last'
      end
    end

    context 'snapshot :pre specified' do
      let(:snapshot_name) { :pre }
      include_examples 'a non-moving snapshot'
    end

    context 'snapshot :post specified' do
      let(:snapshot_name) { :post }
      include_examples 'a non-moving snapshot'
    end

    context 'snapshot :last specified' do
      let(:snapshot_name) { :last }
      include_examples 'snapshot :last'
    end

    context 'snapshot :donkey specified' do
      let(:snapshot_name) { :donkey }
      include_examples 'a non-moving snapshot'
    end
  end
end
