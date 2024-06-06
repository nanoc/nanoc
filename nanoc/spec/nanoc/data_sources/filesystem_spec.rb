# frozen_string_literal: true

describe Nanoc::DataSources::Filesystem, site: true do
  let(:data_source) { described_class.new(site.config, nil, nil, params) }
  let(:now) { Time.local(2008, 1, 2, 14, 5, 0) }
  let(:params) { {} }
  let(:site) { Nanoc::Core::SiteLoader.new.new_from_cwd }

  describe '#load_objects' do
    subject { data_source.send(:load_objects, dir_with_objects, klass) }

    let(:dir_with_objects) { 'foo' }
    let(:klass) { raise 'override me' }

    context 'items' do
      let(:klass) { Nanoc::Core::Item }

      context 'no files' do
        it 'loads nothing' do
          expect(subject).to be_empty
        end
      end

      context 'one textual file' do
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
          expect(subject[0].identifier).to eq(Nanoc::Core::Identifier.new('/bar/', type: :legacy))
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
            expect(&block).to change { data_source.send(:load_objects, 'foo', klass)[0].attributes_checksum_data }
          end

          it 'has the same content checksum' do
            expect(&block).not_to change { data_source.send(:load_objects, 'foo', klass)[0].content_checksum_data }
          end
        end
      end

      context 'one binary file' do
        before do
          FileUtils.mkdir_p('foo')
          File.write('foo/bar.dat', "---\nnum: 1\n---\ntest 1")
          FileUtils.touch('foo/bar.dat', mtime: now)
        end

        let(:expected_attributes) do
          {
            content_filename: 'foo/bar.dat',
            extension: 'dat',
            filename: 'foo/bar.dat',
            meta_filename: nil,
            mtime: now,
          }
        end

        it 'loads that file' do
          expect(subject.size).to eq(1)

          expect(subject[0].content).to be_a(Nanoc::Core::BinaryContent)
          expect(subject[0].attributes).to eq(expected_attributes)
          expect(subject[0].identifier).to eq(Nanoc::Core::Identifier.new('/bar/', type: :legacy))
          expect(subject[0].checksum_data).to be_nil
          expect(subject[0].attributes_checksum_data).to be_a(String)
          expect(subject[0].attributes_checksum_data.size).to eq(20)
        end

        it 'has no content checksum data' do
          expect(subject[0].content_checksum_data).to be_nil
        end
      end

      context 'two content files (no inline metadata) with one meta file' do
        let(:params) { { identifier_type: 'full' } }

        before do
          FileUtils.mkdir_p('foo')
          File.write('foo/a.txt', 'hi')
          File.write('foo/a.md', 'ho')
          File.write('foo/a.yaml', 'title: Aaah')
        end

        it 'errors' do
          expect { subject }
            .to raise_error(
              Nanoc::DataSources::Filesystem::AmbiguousMetadataAssociationError,
              'There are multiple content files (foo/a.md, foo/a.txt) that could match the file containing metadata (foo/a.yaml).',
            )
        end
      end

      context 'two content files (one has inline metadata) with one meta file' do
        let(:params) { { identifier_type: 'full' } }

        before do
          FileUtils.mkdir_p('foo')
          File.write('foo/a.txt', "---\ntitle: Hi\n---\n\nhi")
          File.write('foo/a.md', 'ho')
          File.write('foo/a.yaml', 'title: Aaah')
        end

        it 'assigns metadata to the file that doesn’t have any yet' do
          expect(subject.size).to eq(2)

          items = subject.sort_by { |i| i.identifier.to_s }

          expect(items[0].content).to be_a(Nanoc::Core::TextualContent)
          expect(items[0].identifier).to eq(Nanoc::Core::Identifier.new('/a.md', type: :full))
          expect(items[0].attributes[:title]).to eq('Aaah')

          expect(items[1].content).to be_a(Nanoc::Core::TextualContent)
          expect(items[1].identifier).to eq(Nanoc::Core::Identifier.new('/a.txt', type: :full))
          expect(items[1].attributes[:title]).to eq('Hi')
        end
      end

      context 'two content files (both have inline metadata) with one meta file' do
        let(:params) { { identifier_type: 'full' } }

        before do
          FileUtils.mkdir_p('foo')
          File.write('foo/a.txt', "---\ntitle: Hi\n---\n\nhi")
          File.write('foo/a.md', "---\ntitle: Ho\n---\n\nho")
          File.write('foo/a.yaml', 'title: Aaah')
        end

        it 'errors' do
          expect { subject }
            .to raise_error(
              Nanoc::DataSources::Filesystem::AmbiguousMetadataAssociationError,
              'There are multiple content files (foo/a.md, foo/a.txt) that could match the file containing metadata (foo/a.yaml).',
            )
        end
      end

      context 'two content files (both have inline metadata) with no meta file' do
        let(:params) { { identifier_type: 'full' } }

        before do
          FileUtils.mkdir_p('foo')
          File.write('foo/a.txt', "---\ntitle: Hi\n---\n\nhi")
          File.write('foo/a.md', "---\ntitle: Ho\n---\n\nho")
        end

        it 'uses inline metadata' do
          expect(subject.size).to eq(2)

          items = subject.sort_by { |i| i.identifier.to_s }

          expect(items[0].content).to be_a(Nanoc::Core::TextualContent)
          expect(items[0].identifier).to eq(Nanoc::Core::Identifier.new('/a.md', type: :full))
          expect(items[0].attributes[:title]).to eq('Ho')

          expect(items[1].content).to be_a(Nanoc::Core::TextualContent)
          expect(items[1].identifier).to eq(Nanoc::Core::Identifier.new('/a.txt', type: :full))
          expect(items[1].attributes[:title]).to eq('Hi')
        end
      end

      context 'two content files (neither have inline metadata) with no meta file' do
        let(:params) { { identifier_type: 'full' } }

        before do
          FileUtils.mkdir_p('foo')
          File.write('foo/a.txt', 'hi')
          File.write('foo/a.md', 'ho')
        end

        it 'uses no metadata' do
          expect(subject.size).to eq(2)

          items = subject.sort_by { |i| i.identifier.to_s }

          expect(items[0].content).to be_a(Nanoc::Core::TextualContent)
          expect(items[0].identifier).to eq(Nanoc::Core::Identifier.new('/a.md', type: :full))
          expect(items[0].attributes[:title]).to be_nil

          expect(items[1].content).to be_a(Nanoc::Core::TextualContent)
          expect(items[1].identifier).to eq(Nanoc::Core::Identifier.new('/a.txt', type: :full))
          expect(items[1].attributes[:title]).to be_nil
        end
      end

      context 'one content file (with inline metadata) and a meta file' do
        let(:params) { { identifier_type: 'full' } }

        before do
          FileUtils.mkdir_p('foo')
          File.write('foo/a.txt', "---\ntitle: Hi\n---\n\nhi")
          File.write('foo/a.yaml', 'author: Denis')
        end

        it 'uses only metadata from meta file' do
          expect(subject.size).to eq(1)

          expect(subject[0].content).to be_a(Nanoc::Core::TextualContent)
          expect(subject[0].content.string).to eq("---\ntitle: Hi\n---\n\nhi")
          expect(subject[0].identifier).to eq(Nanoc::Core::Identifier.new('/a.txt', type: :full))
          expect(subject[0].attributes[:title]).to be_nil
          expect(subject[0].attributes[:author]).to eq('Denis')
        end
      end

      context 'content file outside of current working directory' do
        let(:params) { { identifier_type: 'full' } }

        let(:dir_with_objects) { Dir.mktmpdir }

        before do
          File.write(File.join(dir_with_objects, 'foo.txt'), "---\ntitle: I am foo\n---\n\nHi!")
        end

        it 'assigns metadata to the file that doesn’t have any yet' do
          expect(subject.size).to eq(1)

          items = subject.sort_by { |i| i.identifier.to_s }

          expect(items[0].content).to be_a(Nanoc::Core::TextualContent)
          expect(items[0].identifier).to eq(Nanoc::Core::Identifier.new('/foo.txt', type: :full))
          expect(items[0].attributes[:title]).to eq('I am foo')
          expect(items[0].attributes[:content_filename]).to start_with('../')
          expect(items[0].attributes[:content_filename]).to end_with('/foo.txt')
        end
      end
    end
  end

  describe '#changes_for_dir' do
    subject { data_source.changes_for_dir(temp_dir_base_unexpanded) }

    let(:temp_dir_base_unexpanded) { '~/tmp_nanoc_Mj2glnoP' }
    let(:temp_dir_base_expanded) { File.expand_path(temp_dir_base_unexpanded) }
    let(:temp_dir) { Dir.mktmpdir(nil, temp_dir_base_expanded) }

    before do
      if Nanoc::Core.on_windows?
        skip 'nanoc-live is not currently supported on Windows'
      end
    end

    context 'when directory exists' do
      before do
        FileUtils.mkdir_p(temp_dir_base_expanded)
      end

      after do
        FileUtils.rm_rf(temp_dir_base_expanded)
      end

      it 'returns a stream' do
        expect(subject).to be_a(Nanoc::Core::ChangesStream)
      end

      it 'contains one element after changing' do
        FileUtils.mkdir_p(File.join(temp_dir, 'content'))

        enum = SlowEnumeratorTools.buffer(subject.to_enum, 1)
        q = SizedQueue.new(1)
        Thread.new { q << enum.take(1).first }

        # Try until we find a change
        ok = false
        20.times do |i|
          File.write(File.join(temp_dir, 'content/wat.md'), "stuff #{i}")
          begin
            expect(q.pop(true)).to eq(:unknown)
            ok = true
            break
          rescue ThreadError
            sleep 0.1
          end
        end
        expect(ok).to be(true)

        subject.stop
      end
    end

    context 'when directory does not exist' do
      it 'returns a stream' do
        expect(subject).to be_a(Nanoc::Core::ChangesStream)
      end

      it 'does not raise' do
        subject

        t = Thread.new do
          Thread.current.abort_on_exception = true
          Thread.current.report_on_exception = false

          begin
            Timeout.timeout(0.1) { subject.to_enum.take(1).first }
            Thread.current[:outcome] = :not_timed_out
          rescue Timeout::Error
            Thread.current[:outcome] = :timed_out
          end
        end

        t.join
        expect(t[:outcome]).to eq(:timed_out)

        subject.stop
      end
    end
  end
end
