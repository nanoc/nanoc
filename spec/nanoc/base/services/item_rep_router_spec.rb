describe(Nanoc::Int::ItemRepRouter) do
  subject(:item_rep_router) { described_class.new(reps, action_provider, site) }

  let(:reps) { double(:reps) }
  let(:action_provider) { double(:action_provider) }
  let(:site) { double(:site, config: config) }
  let(:config) { Nanoc::Int::Configuration.new.with_defaults }

  describe '#run' do
    subject { item_rep_router.run }

    let(:item) { Nanoc::Int::Item.new('content', {}, '/foo.md') }

    let(:reps) do
      [
        Nanoc::Int::ItemRep.new(item, :default),
        Nanoc::Int::ItemRep.new(item, :csv),
      ]
    end

    let(:memory_without_paths) do
      actions =
        [
          Nanoc::Int::ProcessingActions::Filter.new(:erb, {}),
          Nanoc::Int::ProcessingActions::Snapshot.new([], []),
        ]

      Nanoc::Int::ActionSequence.new(nil, actions: actions)
    end

    let(:action_sequence_for_default) do
      actions =
        [
          Nanoc::Int::ProcessingActions::Filter.new(:erb, {}),
          Nanoc::Int::ProcessingActions::Snapshot.new([:last], ['/foo/index.html']),
        ]

      Nanoc::Int::ActionSequence.new(nil, actions: actions)
    end

    let(:action_sequence_for_csv) do
      actions =
        [
          Nanoc::Int::ProcessingActions::Filter.new(:erb, {}),
          Nanoc::Int::ProcessingActions::Snapshot.new([:last], ['/foo.csv']),
        ]

      Nanoc::Int::ActionSequence.new(nil, actions: actions)
    end

    example do
      allow(action_provider).to receive(:action_sequence_for).with(reps[0]).and_return(action_sequence_for_default)
      allow(action_provider).to receive(:action_sequence_for).with(reps[1]).and_return(action_sequence_for_csv)

      subject

      expect(reps[0].raw_paths).to eql(last: ['output/foo/index.html'])
      expect(reps[0].paths).to eql(last: ['/foo/'])

      expect(reps[1].raw_paths).to eql(last: ['output/foo.csv'])
      expect(reps[1].paths).to eql(last: ['/foo.csv'])
    end

    it 'picks the paths last returned' do
      allow(action_provider).to receive(:action_sequence_for)
        .with(reps[0]).and_return(memory_without_paths, action_sequence_for_default)
      allow(action_provider).to receive(:action_sequence_for)
        .with(reps[1]).and_return(memory_without_paths, action_sequence_for_csv)

      subject

      expect(reps[0].raw_paths).to eql(last: ['output/foo/index.html'])
      expect(reps[0].paths).to eql(last: ['/foo/'])

      expect(reps[1].raw_paths).to eql(last: ['output/foo.csv'])
      expect(reps[1].paths).to eql(last: ['/foo.csv'])
    end
  end

  describe '#route_rep' do
    subject { item_rep_router.route_rep(rep, paths, snapshot_names, paths_to_reps) }

    let(:snapshot_names) { [:foo] }
    let(:rep) { Nanoc::Int::ItemRep.new(item, :default) }
    let(:item) { Nanoc::Int::Item.new('content', {}, '/foo.md') }
    let(:paths_to_reps) { {} }

    context 'basic path is nil' do
      let(:paths) { [] }

      it 'assigns no paths' do
        subject
        expect(rep.raw_paths[:foo]).to be_empty
      end
    end

    context 'basic path is not nil' do
      let(:paths) { ['/foo/index.html'] }

      context 'other snapshot with this path already exists' do
        let(:paths_to_reps) { { '/foo/index.html' => Nanoc::Int::ItemRep.new(item, :other) } }

        it 'errors' do
          expect { subject }.to raise_error(Nanoc::Int::ItemRepRouter::IdenticalRoutesError)
        end
      end

      context 'path is unique' do
        context 'single path' do
          it 'sets the raw path' do
            subject
            expect(rep.raw_paths).to eql(foo: ['output/foo/index.html'])
          end

          it 'sets the path' do
            subject
            expect(rep.paths).to eql(foo: ['/foo/'])
          end

          it 'adds to paths_to_reps' do
            subject
            expect(paths_to_reps).to have_key('/foo/index.html')
          end

          context 'path does not start with a slash' do
            let(:paths) { ['foo/index.html'] }

            it 'errors' do
              expect { subject }.to raise_error(Nanoc::Int::ItemRepRouter::RouteWithoutSlashError)
            end
          end

          context 'path is not UTF-8' do
            let(:paths) { ['/foo/index.html'.encode('ISO-8859-1')] }

            it 'sets the path as UTF-8' do
              subject
              expect(rep.paths).to eql(foo: ['/foo/'])
              expect(rep.paths[:foo].first.encoding.to_s).to eql('UTF-8')
            end

            it 'sets the raw path as UTF-8' do
              subject
              expect(rep.raw_paths).to eql(foo: ['output/foo/index.html'])
              expect(rep.raw_paths[:foo].first.encoding.to_s).to eql('UTF-8')
            end
          end
        end

        context 'multiple paths' do
          let(:paths) { ['/foo/index.html', '/bar/index.html'] }

          it 'sets the raw paths' do
            subject
            expect(rep.raw_paths).to eql(foo: ['output/foo/index.html', 'output/bar/index.html'])
          end

          it 'sets the paths' do
            subject
            expect(rep.paths).to eql(foo: ['/foo/', '/bar/'])
          end

          it 'adds to paths_to_reps' do
            subject
            expect(paths_to_reps).to have_key('/foo/index.html')
            expect(paths_to_reps).to have_key('/bar/index.html')
          end
        end
      end
    end
  end

  describe '#strip_index_filename' do
    subject { item_rep_router.strip_index_filename(basic_path) }

    context 'basic path ends with /index.html' do
      let(:basic_path) { '/bar/index.html' }
      it { is_expected.to eql('/bar/') }
    end

    context 'basic path contains /index.html' do
      let(:basic_path) { '/bar/index.html/foo' }
      it { is_expected.to eql('/bar/index.html/foo') }
    end

    context 'basic path ends with xindex.html' do
      let(:basic_path) { '/bar/xindex.html' }
      it { is_expected.to eql('/bar/xindex.html') }
    end

    context 'basic path does not contain /index.html' do
      let(:basic_path) { '/bar/foo.html' }
      it { is_expected.to eql('/bar/foo.html') }
    end
  end
end
