# frozen_string_literal: true

describe Nanoc::DataSources::Filesystem::Parser do
  subject(:parser) { described_class.new(config:) }

  let(:config) do
    Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults
  end

  describe '#call' do
    subject { parser.call(content_filename, meta_filename) }

    let(:content_filename) { nil }
    let(:meta_filename) { nil }

    context 'only meta file' do
      let(:meta_filename) { 'test_meta.txt' }

      before do
        File.write(meta_filename, meta)
      end

      context 'simple metadata' do
        let(:meta) { "foo: bar\n" }

        it 'reads attributes' do
          expect(subject.attributes).to eq('foo' => 'bar')
        end

        it 'has no content' do
          expect(subject.content).to eq('')
        end
      end

      context 'UTF-8 bom' do
        let(:meta) { [0xEF, 0xBB, 0xBF].map(&:chr).join + "foo: bar\r\n" }

        it 'strips UTF-8 BOM' do
          expect(subject.attributes).to eq('foo' => 'bar')
        end

        it 'has no content' do
          expect(subject.content).to eq('')
        end
      end

      context 'CRLF' do
        let(:meta) { "foo: bar\r\n" }

        it 'handles CR+LF line endings' do
          expect(subject.attributes).to eq('foo' => 'bar')
        end

        it 'has no content' do
          expect(subject.content).to eq('')
        end
      end

      context 'metadata is empty' do
        let(:meta) { '' }

        it 'has no attributes' do
          expect(subject.attributes).to eq({})
        end

        it 'has no content' do
          expect(subject.content).to eq('')
        end
      end

      context 'metadata is not hash' do
        let(:meta) { "- stuff\n" }

        it 'raises' do
          expect { subject }
            .to raise_error(Nanoc::DataSources::Filesystem::Errors::InvalidMetadata, /has invalid metadata \(expected key-value pairs, found Array instead\)/)
        end
      end
    end

    context 'only content file' do
      let(:content_filename) { 'test_content.txt' }

      before do
        File.write(content_filename, content)
      end

      context 'no metadata section' do
        context 'simple' do
          let(:content) { "Hello!\n" }

          it 'has no attributes' do
            expect(subject.attributes).to eq({})
          end

          it 'has content' do
            expect(subject.content).to eq("Hello!\n")
          end
        end

        context 'UTF-8 bom' do
          let(:content) { [0xEF, 0xBB, 0xBF].map(&:chr).join + "Hello!\n" }

          it 'has no attributes' do
            expect(subject.attributes).to eq({})
          end

          it 'strips UTF-8 BOM' do
            expect(subject.content).to eq("Hello!\n")
          end
        end

        context 'CRLF' do
          let(:content) { "Hello!\r\n" }

          it 'has no attributes' do
            expect(subject.attributes).to eq({})
          end

          it 'retains CR+LF' do
            # FIXME: Is this the right thing to do?
            expect(subject.content).to eq("Hello!\r\n")
          end
        end
      end

      context 'metadata section' do
        context 'three dashes' do
          let(:content) { "---\ntitle: Welcome\n---\nHello!\n" }

          it 'has attributes' do
            expect(subject.attributes).to eq('title' => 'Welcome')
          end

          it 'has content' do
            expect(subject.content).to eq("Hello!\n")
          end
        end

        context 'five dashes' do
          let(:content) { "-----\ntitle: Welcome\n-----\nHello!\n" }

          it 'has attributes' do
            expect(subject.attributes).to eq('title' => 'Welcome')
          end

          it 'has content' do
            expect(subject.content).to eq("Hello!\n")
          end
        end

        context 'trailing spaces' do
          let(:content) { "---   \ntitle: Welcome   \n---   \nHello!   \n" }

          it 'has attributes' do
            expect(subject.attributes).to eq('title' => 'Welcome')
          end

          it 'has content' do
            expect(subject.content).to eq("Hello!   \n")
          end
        end

        context 'diff' do
          let(:content) { "--- a/foo\n+++ b/foo\nblah blah\n" }

          it 'has no attributes' do
            expect(subject.attributes).to eq({})
          end

          it 'has content' do
            expect(subject.content).to eq(content)
          end
        end

        context 'separator not at beginning' do
          let(:content) { "foo\n---\ntitle: Welcome\n---\nStuff\n" }

          it 'has no attributes' do
            expect(subject.attributes).to eq({})
          end

          it 'has content' do
            expect(subject.content).to eq(content)
          end
        end

        context 'unterminated metadata section' do
          let(:content) { "---\ntitle: Welcome\n" }

          it 'raises' do
            expect { subject }.to raise_error(Nanoc::DataSources::Filesystem::Errors::InvalidFormat)
          end
        end

        context 'non-hash metadata section' do
          let(:content) { "---\nWelcome\n---\nHello!\n" }

          it 'raises' do
            expect { subject }.to raise_error(Nanoc::DataSources::Filesystem::Errors::InvalidMetadata)
          end
        end

        context 'empty metadata section' do
          let(:content) { "---\n---\nHello!\n" }

          it 'has no attributes' do
            expect(subject.attributes).to eq({})
          end

          it 'has content' do
            expect(subject.content).to eq("Hello!\n")
          end
        end

        context 'leading newline' do
          let(:content) { "---\ntitle: Welcome\n---\n\nHello!\n" }

          it 'has attributes' do
            expect(subject.attributes).to eq('title' => 'Welcome')
          end

          it 'has content' do
            expect(subject.content).to eq("Hello!\n")
          end
        end

        context 'two leading newlines' do
          let(:content) { "---\ntitle: Welcome\n---\n\n\nHello!\n" }

          it 'has attributes' do
            expect(subject.attributes).to eq('title' => 'Welcome')
          end

          it 'has content with one leading newline' do
            expect(subject.content).to eq("\nHello!\n")
          end
        end

        context 'date attribute' do
          let(:content) { "---\ncreated_at: 2022-01-01\n---" }

          it 'has attributes' do
            if Psych::VERSION <= '4.0.6' && Timecop::VERSION <= '0.9.5'
              skip <<~MESSAGE.lines.map(&:chomp).join(' ')
                Psych 4.0.5 introduces an incompatibility with Timecop 0.9.5,
                which causes dates not to be parsed correctly (see
                https://github.com/travisjeffery/timecop/issues/390).
              MESSAGE
            end

            expect(subject.attributes).to eq('created_at' => Date.new(2022, 1, 1))
          end
        end

        context 'time attribute' do
          let(:content) { "---\ncreated_at: 2022-01-01T14:05:00+04:00\n---" }

          it 'has attributes' do
            expect(subject.attributes).to eq('created_at' => Time.new(2022, 1, 1, 14, 5, 0, '+04:00'))
          end
        end

        context 'no content' do
          let(:content) { "---\ntitle: Welcome\n---\n" }

          it 'has attributes' do
            expect(subject.attributes).to eq('title' => 'Welcome')
          end

          it 'has no content' do
            expect(subject.content).to eq('')
          end
        end

        context 'UTF-8 bom' do
          let(:content) { [0xEF, 0xBB, 0xBF].map(&:chr).join + "---\ntitle: Welcome\n---\nHello!\n" }

          it 'has attributes' do
            expect(subject.attributes).to eq('title' => 'Welcome')
          end

          it 'strips UTF-8 BOM' do
            expect(subject.content).to eq("Hello!\n")
          end
        end

        context 'CRLF' do
          let(:content) { "---\r\ntitle: Welcome\r\n---\r\nHello!\r\n" }

          it 'has attributes' do
            expect(subject.attributes).to eq('title' => 'Welcome')
          end

          it 'retains CR+LF' do
            # FIXME: Is this the right thing to do?
            expect(subject.content).to eq("Hello!\r\n")
          end
        end

        context 'four dashes' do
          let(:content) { "----\ntitle: Welcome\n----\nHello!\n" }

          it 'has no attributes' do
            expect(subject.attributes).to eq({})
          end

          it 'has unparsed content' do
            expect(subject.content).to eq(content)
          end
        end

        context 'additional separators' do
          let(:content) { "---\ntitle: Welcome\n---\nHello!\n---\nStuff\n" }

          it 'has attributes' do
            expect(subject.attributes).to eq('title' => 'Welcome')
          end

          it 'has content' do
            expect(subject.content).to eq("Hello!\n---\nStuff\n")
          end
        end
      end
    end

    context 'meta and content file' do
      let(:content_filename) { 'test_content.txt' }
      let(:meta_filename) { 'test_meta.txt' }

      before do
        File.write(content_filename, content)
        File.write(meta_filename, meta)
      end

      context 'simple' do
        let(:content) { "Hello\n" }
        let(:meta) { "title: Welcome\n" }

        it 'has attributes' do
          expect(subject.attributes).to eq('title' => 'Welcome')
        end

        it 'has content' do
          expect(subject.content).to eq("Hello\n")
        end
      end

      context 'apparent metadata section' do
        let(:content) { "---\nauthor: Denis\n---\nHello!\n" }
        let(:meta) { "title: Welcome\n" }

        it 'has attributes' do
          expect(subject.attributes).to eq('title' => 'Welcome')
        end

        it 'does not parse content' do
          expect(subject.content).to eq(content)
        end
      end

      context 'CRLF' do
        let(:content) { "Hello!\r\n" }
        let(:meta) { "title: Welcome\r\n" }

        it 'has attributes' do
          expect(subject.attributes).to eq('title' => 'Welcome')
        end

        it 'has content' do
          # FIXME: Is this the right thing to do?
          expect(subject.content).to eq("Hello!\r\n")
        end
      end

      context 'UTF-8 bom' do
        let(:content) { [0xEF, 0xBB, 0xBF].map(&:chr).join + "Hello!\n" }
        let(:meta) { [0xEF, 0xBB, 0xBF].map(&:chr).join + "title: Welcome\n" }

        it 'has attributes' do
          expect(subject.attributes).to eq('title' => 'Welcome')
        end

        it 'has content' do
          expect(subject.content).to eq("Hello!\n")
        end
      end
    end
  end
end
