# frozen_string_literal: true

describe Nanoc::DataSources::Filesystem do
  let(:data_source) { Nanoc::DataSources::Filesystem.new(site.config, nil, nil, params) }
  let(:params) { {} }
  let(:site) { Nanoc::Int::SiteLoader.new.new_empty }

  before { Timecop.freeze(now) }
  after { Timecop.return }

  let(:now) { Time.local(2008, 1, 2, 14, 5, 0) }

  describe '#load_objects' do
    subject { data_source.send(:load_objects, 'foo', klass) }

    let(:klass) { raise 'override me' }

    context 'items' do
      let(:klass) { Nanoc::Int::Item }

      context 'no files' do
        it 'loads nothing' do
          expect(subject).to be_empty
        end
      end

      context 'one regular file' do
        before do
          FileUtils.mkdir_p('foo')
          File.write('foo/bar.html', "---\nnum: 1\n---\ntest 1")
          FileUtils.touch('foo/bar.html', mtime: now)
        end

        let(:expected_attributes) do
          {
            content_filename: 'foo/bar.html',
            extension: 'html',
            filename: 'foo/bar.html',
            meta_filename: nil,
            mtime: now,
            num: 1,
          }
        end

        it 'loads that file' do
          expect(subject.size).to eq(1)

          expect(subject[0].content.string).to eq('test 1')
          expect(subject[0].attributes).to eq(expected_attributes)
          expect(subject[0].identifier).to eq(Nanoc::Identifier.new('/bar/', type: :legacy))
          expect(subject[0].checksum_data).to be_nil
          expect(subject[0].attributes_checksum_data).to be_a(String)
          expect(subject[0].attributes_checksum_data.size).to eq(20)
          expect(subject[0].content_checksum_data).to be_a(String)
          expect(subject[0].content_checksum_data.size).to eq(20)
        end

        context 'split files' do
          let(:block) do
            lambda do
              FileUtils.mkdir_p('foo')

              File.write('foo/bar.html', 'test 1')
              FileUtils.touch('foo/bar.html', mtime: now)

              File.write('foo/bar.yaml', "---\nnum: 1\n")
              FileUtils.touch('foo/bar.yaml', mtime: now)
            end
          end

          it 'has a different attributes checksum' do
            expect(block).to change { data_source.send(:load_objects, 'foo', klass)[0].attributes_checksum_data }
          end

          it 'has the same content checksum' do
            expect(block).not_to change { data_source.send(:load_objects, 'foo', klass)[0].content_checksum_data }
          end
        end
      end
    end
  end

  describe '#item_changes' do
    subject { data_source.item_changes }

    before do
      if Nanoc.on_windows?
        skip 'nanoc-live is not currently supported on Windows'
      end
    end

    it 'returns a stream' do
      expect(subject).to be_a(Nanoc::ChangesStream)
    end

    it 'contains one element after changing' do
      FileUtils.mkdir_p('content')

      enum = SlowEnumeratorTools.buffer(subject.to_enum, 1)
      q = SizedQueue.new(1)
      Thread.new { q << enum.take(1).first }

      # FIXME: sleep is ugly
      sleep 0.3
      File.write('content/wat.md', 'stuff')

      expect(q.pop).to eq(:unknown)
      subject.stop
    end
  end

  describe '#layout_changes' do
    subject { data_source.layout_changes }

    before do
      if Nanoc.on_windows?
        skip 'nanoc-live is not currently supported on Windows'
      end
    end

    it 'returns a stream' do
      expect(subject).to be_a(Nanoc::ChangesStream)
    end

    it 'contains one element after changing' do
      FileUtils.mkdir_p('layouts')

      enum = SlowEnumeratorTools.buffer(subject.to_enum, 1)
      q = SizedQueue.new(1)
      Thread.new { q << enum.take(1).first }

      # FIXME: sleep is ugly
      sleep 0.3
      File.write('layouts/wat.md', 'stuff')

      expect(q.pop).to eq(:unknown)
      subject.stop
    end
  end
end
