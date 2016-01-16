describe Nanoc::RuleDSL::RecordingExecutor do
  let(:executor) { described_class.new(rep, rules_collection, site) }

  let(:rep) { double(:rep) }
  let(:rules_collection) { double(:rules_collection) }
  let(:site) { double(:site) }

  describe '#filter' do
    it 'records filter call without arguments' do
      executor.filter(rep, :erb)

      expect(executor.rule_memory.size).to eql(1)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Filter)
      expect(executor.rule_memory[0].filter_name).to eql(:erb)
      expect(executor.rule_memory[0].params).to eql({})
    end

    it 'records filter call with arguments' do
      executor.filter(rep, :erb, x: 123)

      expect(executor.rule_memory.size).to eql(1)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Filter)
      expect(executor.rule_memory[0].filter_name).to eql(:erb)
      expect(executor.rule_memory[0].params).to eql({ x: 123 })
    end
  end

  describe '#layout' do
    it 'records layout call without arguments' do
      executor.layout(rep, '/default.*')

      expect(executor.rule_memory.size).to eql(2)

      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
      expect(executor.rule_memory[0].snapshot_name).to eql(:pre)
      expect(executor.rule_memory[0]).to be_final
      expect(executor.rule_memory[0].path).to be_nil

      expect(executor.rule_memory[1]).to be_a(Nanoc::Int::RuleMemoryActions::Layout)
      expect(executor.rule_memory[1].layout_identifier).to eql('/default.*')
      expect(executor.rule_memory[1].params).to eql({})
    end

    it 'records layout call with arguments' do
      executor.layout(rep, '/default.*', final: false)

      expect(executor.rule_memory.size).to eql(2)

      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
      expect(executor.rule_memory[0].snapshot_name).to eql(:pre)
      expect(executor.rule_memory[0]).to be_final
      expect(executor.rule_memory[0].path).to be_nil

      expect(executor.rule_memory[1]).to be_a(Nanoc::Int::RuleMemoryActions::Layout)
      expect(executor.rule_memory[1].layout_identifier).to eql('/default.*')
      expect(executor.rule_memory[1].params).to eql({ final: false })
    end
  end

  describe '#snapshot' do
    let(:rules_collection) do
      Nanoc::RuleDSL::RulesCollection.new
    end

    context 'snapshot already exists' do
      before do
        executor.snapshot(rep, :foo)
      end

      it 'raises when creating same snapshot' do
        expect { executor.snapshot(rep, :foo) }
          .to raise_error(Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName)
      end
    end

    context 'no arguments' do
      subject { executor.snapshot(rep, :foo) }

      it 'records' do
        subject
        expect(executor.rule_memory.size).to eql(1)
        expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
        expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
        expect(executor.rule_memory[0].path).to be_nil
        expect(executor.rule_memory[0]).to be_final
      end
    end

    context 'final argument' do
      subject { executor.snapshot(rep, :foo, final: final, path: path) }
      let(:path) { nil }

      context 'final' do
        let(:final) { true }

        context 'routing rule does not exist' do
          context 'no explicit path given' do
            it 'records' do
              subject
              expect(executor.rule_memory.size).to eql(1)
              expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
              expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
              expect(executor.rule_memory[0].path).to be_nil
              expect(executor.rule_memory[0]).to be_final
            end
          end

          context 'explicit path given' do
            let(:path) { '/routed-foo.html' }

            it 'records' do
              subject
              expect(executor.rule_memory.size).to eql(1)
              expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
              expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
              expect(executor.rule_memory[0].path).to eql('/routed-foo.html')
              expect(executor.rule_memory[0]).to be_final
            end
          end
        end

        context 'routing rule exists' do
          let(:item) { Nanoc::Int::Item.new('', {}, '/foo.md') }
          let(:route_proc) { proc { '/routed-foo.html' } }

          before do
            rules_collection.add_item_routing_rule(
              Nanoc::RuleDSL::Rule.new(
                Nanoc::Int::Pattern.from('/foo.*'),
                :default,
                route_proc,
                snapshot_name: :foo,
              ),
            )

            allow(rep).to receive(:item).and_return(item)
            allow(rep).to receive(:name).and_return(:default)
            allow(site).to receive(:items).and_return(double(:items))
            allow(site).to receive(:layouts).and_return(double(:layouts))
            allow(site).to receive(:config).and_return(double(:config))
          end

          context 'no explicit path given' do
            context 'routing rule returns path not starting with a slash' do
              let(:route_proc) { proc { 'routed-foo.html' } }

              it 'errors' do
                expect { subject }.to raise_error(Nanoc::RuleDSL::RecordingExecutor::PathWithoutInitialSlashError)
              end
            end

            it 'records' do
              subject
              expect(executor.rule_memory.size).to eql(1)
              expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
              expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
              expect(executor.rule_memory[0].path).to eql('/routed-foo.html')
              expect(executor.rule_memory[0]).to be_final
            end
          end

          context 'explicit path given' do
            let(:path) { '/routed-foo-from-path.html' }

            it 'uses the explicit path' do
              subject
              expect(executor.rule_memory.size).to eql(1)
              expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
              expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
              expect(executor.rule_memory[0].path).to eql('/routed-foo-from-path.html')
              expect(executor.rule_memory[0]).to be_final
            end
          end
        end
      end

      context 'not final' do
        let(:final) { false }

        it 'records' do
          subject

          expect(executor.rule_memory.size).to eql(1)
          expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
          expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
          expect(executor.rule_memory[0].path).to be_nil
          expect(executor.rule_memory[0]).not_to be_final
        end

        context 'explicit path given' do
          let(:path) { '/routed-foo.html' }

          it 'records without path' do
            subject

            expect(executor.rule_memory.size).to eql(1)
            expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
            expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
            expect(executor.rule_memory[0].path).to be_nil
            expect(executor.rule_memory[0]).not_to be_final
          end
        end

        context 'routing rule exists' do
          let(:item) { Nanoc::Int::Item.new('', {}, '/foo.md') }

          before do
            rules_collection.add_item_routing_rule(
              Nanoc::RuleDSL::Rule.new(
                Nanoc::Int::Pattern.from('/foo.*'),
                :default,
                proc { '/routed-foo.html' },
                snapshot_name: :foo,
              ),
            )

            allow(rep).to receive(:item).and_return(item)
            allow(rep).to receive(:name).and_return(:default)
            allow(site).to receive(:items).and_return(double(:items))
            allow(site).to receive(:layouts).and_return(double(:layouts))
            allow(site).to receive(:config).and_return(double(:config))
          end

          it 'records without path' do
            subject

            expect(executor.rule_memory.size).to eql(1)
            expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
            expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
            expect(executor.rule_memory[0].path).to be_nil
            expect(executor.rule_memory[0]).not_to be_final
          end
        end
      end
    end

    it 'records snapshot call with final argument' do
      executor.snapshot(rep, :foo, final: false)

      expect(executor.rule_memory.size).to eql(1)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
      expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
      expect(executor.rule_memory[0]).not_to be_final
    end

    it 'raises when given unknown arguments' do
      expect { executor.snapshot(rep, :foo, animal: 'giraffe') }
        .to raise_error(ArgumentError)
    end

    it 'can create multiple snapshots with different names' do
      executor.snapshot(rep, :foo)
      executor.snapshot(rep, :bar)

      expect(executor.rule_memory.size).to eql(2)
      expect(executor.rule_memory[0]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
      expect(executor.rule_memory[0].snapshot_name).to eql(:foo)
      expect(executor.rule_memory[0]).to be_final
      expect(executor.rule_memory[1]).to be_a(Nanoc::Int::RuleMemoryActions::Snapshot)
      expect(executor.rule_memory[1].snapshot_name).to eql(:bar)
      expect(executor.rule_memory[1]).to be_final
    end
  end
end
