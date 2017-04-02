describe(Nanoc::RuleDSL::ActionSequenceCalculator) do
  subject(:action_sequence_calculator) do
    described_class.new(site: site, rules_collection: rules_collection)
  end

  let(:rules_collection) { Nanoc::RuleDSL::RulesCollection.new }
  let(:site) { double(:site) }

  describe '#[]' do
    subject { action_sequence_calculator[obj] }

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
          error = Nanoc::RuleDSL::ActionSequenceCalculator::NoActionSequenceForItemRepException
          expect { subject }.to raise_error(error)
        end
      end

      context 'rules exist' do
        before do
          rules_proc = proc do
            filter :erb, speed: :over_9000
            layout '/default.*'
            filter :typohero
          end
          rule = Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/list.*'), :csv, rules_proc)
          rules_collection.add_item_compilation_rule(rule)
        end

        example do
          subject

          expect(subject[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
          expect(subject[0].snapshot_names).to eql([:raw])
          expect(subject[0].paths).to be_empty

          expect(subject[1]).to be_a(Nanoc::Int::ProcessingActions::Filter)
          expect(subject[1].filter_name).to eql(:erb)
          expect(subject[1].params).to eql(speed: :over_9000)

          expect(subject[2]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
          expect(subject[2].snapshot_names).to eql([:pre])
          expect(subject[2].paths).to be_empty

          expect(subject[3]).to be_a(Nanoc::Int::ProcessingActions::Layout)
          expect(subject[3].layout_identifier).to eql('/default.*')
          expect(subject[3].params).to be_nil

          expect(subject[4]).to be_a(Nanoc::Int::ProcessingActions::Filter)
          expect(subject[4].filter_name).to eql(:typohero)
          expect(subject[4].params).to eql({})

          expect(subject[5]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
          expect(subject[5].snapshot_names).to eql(%i(post last))
          expect(subject[5].paths).to be_empty

          expect(subject.size).to eql(6)
        end
      end

      context 'no routing rule exists' do
        before do
          # Add compilation rule
          compilation_rule = Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/list.*'), :csv, proc {})
          rules_collection.add_item_compilation_rule(compilation_rule)
        end

        example do
          subject

          expect(subject[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
          expect(subject[0].snapshot_names).to eql(%i(raw last pre))
          expect(subject[0].paths).to be_empty

          expect(subject.size).to eql(1)
        end
      end

      context 'routing rule exists' do
        before do
          # Add compilation rule
          compilation_rule = Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/list.*'), :csv, proc {})
          rules_collection.add_item_compilation_rule(compilation_rule)

          # Add routing rule
          routing_rule = Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/list.*'), :csv, proc { '/foo.md' }, snapshot_name: :last)
          rules_collection.add_item_routing_rule(routing_rule)
        end

        example do
          subject

          expect(subject[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
          expect(subject[0].snapshot_names).to eql(%i(raw last pre))
          expect(subject[0].paths).to eq(['/foo.md'])

          expect(subject.size).to eql(1)
        end
      end

      context 'routing rule for other rep exists' do
        before do
          # Add compilation rule
          compilation_rule = Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/list.*'), :csv, proc {})
          rules_collection.add_item_compilation_rule(compilation_rule)

          # Add routing rule
          routing_rule = Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/list.*'), :abc, proc { '/foo.md' }, snapshot_name: :last)
          rules_collection.add_item_routing_rule(routing_rule)
        end

        example do
          subject

          expect(subject[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
          expect(subject[0].snapshot_names).to eql(%i(raw last pre))
          expect(subject[0].paths).to be_empty

          expect(subject.size).to eql(1)
        end
      end
    end

    context 'with layout' do
      let(:obj) { Nanoc::Int::Layout.new('content', {}, '/default.erb') }

      context 'no rules exist' do
        it 'raises error' do
          error = Nanoc::RuleDSL::ActionSequenceCalculator::NoActionSequenceForLayoutException
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
          expect(subject[0].params).to eql(x: 123)
        end
      end
    end

    context 'with something else' do
      let(:obj) { :donkey }

      it 'errors' do
        error = Nanoc::RuleDSL::ActionSequenceCalculator::UnsupportedObjectTypeException
        expect { subject }.to raise_error(error)
      end
    end
  end

  describe '#compact_snapshots' do
    subject { action_sequence_calculator.compact_snapshots(action_sequence) }

    let(:action_sequence) { Nanoc::Int::ActionSequence.new(rep) }
    let(:rep) { double(:rep) }

    before do
      action_sequence.add_snapshot(:a1, nil)
      action_sequence.add_snapshot(:a2, '/a2.md')
      action_sequence.add_snapshot(:a3, nil)
      action_sequence.add_filter(:erb, awesomeness: 'high')
      action_sequence.add_snapshot(:b1, '/b1.md')
      action_sequence.add_snapshot(:b2, nil)
      action_sequence.add_snapshot(:b3, '/b3.md')
      action_sequence.add_filter(:erb, awesomeness: 'high')
      action_sequence.add_snapshot(:c, nil)
    end

    example do
      expect(subject[0]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(subject[0].snapshot_names).to eql(%i(a1 a2 a3))
      expect(subject[0].paths).to eql(['/a2.md'])

      expect(subject[1]).to be_a(Nanoc::Int::ProcessingActions::Filter)

      expect(subject[2]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(subject[2].snapshot_names).to eql(%i(b1 b2 b3))
      expect(subject[2].paths).to eql(['/b1.md', '/b3.md'])

      expect(subject[3]).to be_a(Nanoc::Int::ProcessingActions::Filter)

      expect(subject[4]).to be_a(Nanoc::Int::ProcessingActions::Snapshot)
      expect(subject[4].snapshot_names).to eql([:c])
      expect(subject[4].paths).to be_empty

      expect(subject.size).to eql(5)
    end
  end
end
