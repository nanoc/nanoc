describe(Nanoc::RuleDSL::RuleMemoryCalculator) do
  subject(:rule_memory_calculator) do
    described_class.new(site: site, rules_collection: rules_collection)
  end

  let(:rules_collection) { Nanoc::RuleDSL::RulesCollection.new }
  let(:site) { double(:site) }

  describe '#[]' do
    subject { rule_memory_calculator[obj] }

    context 'with item rep' do
      let(:obj) { Nanoc::Int::ItemRep.new(item, :csv) }

      let(:item) { Nanoc::Int::Item.new('content', {}, Nanoc::Identifier.from('/list.md')) }
      let(:config) { Nanoc::Int::Configuration.new.with_defaults }
      let(:items) { Nanoc::Int::IdentifiableCollection.new(config) }
      let(:layouts) { Nanoc::Int::IdentifiableCollection.new(config) }
      let(:site) { double(:site, items: items, layouts: layouts, config: config, compiler: compiler) }
      let(:compiler) { double(:compiler, compilation_context: compilation_context) }
      let(:compilation_context) { double(:compilation_context) }
      let(:view_context) { double(:view_context) }

      before do
        expect(compilation_context).to receive(:create_view_context).and_return(view_context)
      end

      context 'no rules exist' do
        it 'raises error' do
          error = Nanoc::RuleDSL::RuleMemoryCalculator::NoRuleMemoryForItemRepException
          expect { subject }.to raise_error(error)
        end
      end

      context 'rules exist' do
        example do
          rules_proc = proc do
            filter :erb, speed: :over_9000
            layout '/default.*'
            filter :typohero
          end
          rule = Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/list.*'), :csv, rules_proc)
          rules_collection.add_item_compilation_rule(rule)

          subject

          expect(subject.size).to eql(8)

          expect(subject[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
          expect(subject[0].snapshot_name).to eql(:raw)
          expect(subject[0]).to be_final
          expect(subject[0].path).to be_nil

          expect(subject[1]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
          expect(subject[1].snapshot_name).to eql(:pre)
          expect(subject[1]).not_to be_final
          expect(subject[1].path).to be_nil

          expect(subject[2]).to be_a(Nanoc::Int::ProcessingActions::Filter)
          expect(subject[2].filter_name).to eql(:erb)
          expect(subject[2].params).to eql({ speed: :over_9000 })

          expect(subject[3]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
          expect(subject[3].snapshot_name).to eql(:pre)
          expect(subject[3]).to be_final
          expect(subject[3].path).to be_nil

          expect(subject[4]).to be_a(Nanoc::Int::ProcessingActions::Layout)
          expect(subject[4].layout_identifier).to eql('/default.*')
          expect(subject[4].params).to be_nil

          expect(subject[5]).to be_a(Nanoc::Int::ProcessingActions::Filter)
          expect(subject[5].filter_name).to eql(:typohero)
          expect(subject[5].params).to eql({})

          expect(subject[6]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
          expect(subject[6].snapshot_name).to eql(:post)
          expect(subject[6]).to be_final
          expect(subject[6].path).to be_nil

          expect(subject[7]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
          expect(subject[7].snapshot_name).to eql(:last)
          expect(subject[7]).to be_final
          expect(subject[7].path).to be_nil
        end

        context 'anonymous snapshot followed by :last snapshot' do
          before do
            rules_proc = proc do
              write '/hello.txt'
            end
            rule = Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/list.*'), :csv, rules_proc)
            rules_collection.add_item_compilation_rule(rule)
          end

          it 'merges the two snapshots' do
            subject

            expect(subject.size).to eql(3)

            expect(subject[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(subject[0].snapshot_name).to eql(:raw)
            expect(subject[0]).to be_final
            expect(subject[0].path).to be_nil

            expect(subject[1]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(subject[1].snapshot_name).to eql(:pre)
            expect(subject[1]).not_to be_final
            expect(subject[1].path).to be_nil

            expect(subject[2]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
            expect(subject[2].snapshot_name).to eql(:last)
            expect(subject[2]).to be_final
            expect(subject[2].path).to eq('/hello.txt')
          end
        end
      end
    end

    context 'with layout' do
      let(:obj) { Nanoc::Int::Layout.new('content', {}, '/default.erb') }

      context 'no rules exist' do
        it 'raises error' do
          error = Nanoc::RuleDSL::RuleMemoryCalculator::NoRuleMemoryForLayoutException
          expect { subject }.to raise_error(error)
        end
      end

      context 'rule exists' do
        before do
          pat = Nanoc::Int::Pattern.from('/*.erb')
          rules_collection.layout_filter_mapping[pat] = [:erb, { x: 123 }]
        end

        it 'contains memory for the rule' do
          expect(subject.size).to eql(1)
          expect(subject[0]).to be_a(Nanoc::Int::ProcessingActions::Filter)
          expect(subject[0].filter_name).to eql(:erb)
          expect(subject[0].params).to eql({ x: 123 })
        end
      end
    end

    context 'with something else' do
      let(:obj) { :donkey }

      it 'errors' do
        error = Nanoc::RuleDSL::RuleMemoryCalculator::UnsupportedObjectTypeException
        expect { subject }.to raise_error(error)
      end
    end
  end

  describe '#snapshots_defs_for' do
    subject { rule_memory_calculator.snapshots_defs_for(rep) }

    let(:rep) { Nanoc::Int::ItemRep.new(item, :csv) }

    let(:item) { Nanoc::Int::Item.new('content', {}, Nanoc::Identifier.from('/list.md')) }
    let(:config) { Nanoc::Int::Configuration.new.with_defaults }
    let(:items) { Nanoc::Int::IdentifiableCollection.new(config) }
    let(:layouts) { Nanoc::Int::IdentifiableCollection.new(config) }
    let(:site) { double(:site, items: items, layouts: layouts, config: config, compiler: compiler) }
    let(:compiler) { double(:compiler, compilation_context: compilation_context) }
    let(:compilation_context) { double(:compilation_context) }
    let(:view_context) { double(:view_context) }

    before do
      rules_proc = proc do
        filter :erb, speed: :over_9000
        layout '/default.*'
        filter :typohero
      end
      rule = Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/list.*'), :csv, rules_proc)
      rules_collection.add_item_compilation_rule(rule)

      expect(compilation_context).to receive(:create_view_context).and_return(view_context)
    end

    example do
      expect(subject.size).to eql(5)

      expect(subject[0]).to be_a(Nanoc::Int::SnapshotDef)
      expect(subject[0].name).to eql(:raw)
      expect(subject[0]).to be_final

      expect(subject[1]).to be_a(Nanoc::Int::SnapshotDef)
      expect(subject[1].name).to eql(:pre)
      expect(subject[1]).not_to be_final

      expect(subject[2]).to be_a(Nanoc::Int::SnapshotDef)
      expect(subject[2].name).to eql(:pre)
      expect(subject[2]).to be_final

      expect(subject[3]).to be_a(Nanoc::Int::SnapshotDef)
      expect(subject[3].name).to eql(:post)
      expect(subject[3]).to be_final

      expect(subject[4]).to be_a(Nanoc::Int::SnapshotDef)
      expect(subject[4].name).to eql(:last)
      expect(subject[4]).to be_final
    end
  end
end
