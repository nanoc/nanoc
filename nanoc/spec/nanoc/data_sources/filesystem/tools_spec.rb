# frozen_string_literal: true

describe Nanoc::DataSources::Filesystem::Tools do
  describe '.read_file' do
    subject { described_class.read_file(filename, config:) }

    let(:filename) { 'foo.dat' }
    let(:config) { {} }

    context 'file does not exist' do
      it 'errors' do
        expect { subject }
          .to raise_error(
            Nanoc::DataSources::Filesystem::Errors::FileUnreadable,
            /^Could not read foo.dat:/,
          )
      end
    end

    context 'file exists as ISO-8859-1' do
      before do
        File.write(filename, 'élève'.encode('ISO-8859-1'))
      end

      context 'no config' do
        it 'errors' do
          expect { subject }
            .to raise_error(
              Nanoc::DataSources::Filesystem::Errors::InvalidEncoding,
              'Could not read foo.dat because the file is not valid UTF-8.',
            )
        end
      end

      context 'config with correct encoding' do
        let(:config) do
          { encoding: 'ISO-8859-1' }
        end

        it { is_expected.to eq('élève') }
        its(:encoding) { is_expected.to eq(Encoding::UTF_8) }
      end

      context 'config with incorrect encoding' do
        let(:config) do
          { encoding: 'UTF-16' }
        end

        it 'errors' do
          expect { subject }
            .to raise_error(
              Nanoc::DataSources::Filesystem::Errors::InvalidEncoding,
              'Could not read foo.dat because the file is not valid UTF-16.',
            )
        end
      end
    end

    context 'file exists as UTF-8' do
      before do
        File.write(filename, 'élève'.encode('UTF-8'))
      end

      context 'no config' do
        it { is_expected.to eq('élève') }
        its(:encoding) { is_expected.to eq(Encoding::UTF_8) }
      end

      context 'config with correct encoding' do
        let(:config) do
          { encoding: 'UTF-8' }
        end

        it { is_expected.to eq('élève') }
        its(:encoding) { is_expected.to eq(Encoding::UTF_8) }
      end

      context 'config with incorrect encoding' do
        let(:config) do
          { encoding: 'UTF-16' }
        end

        it 'errors' do
          expect { subject }
            .to raise_error(
              Nanoc::DataSources::Filesystem::Errors::InvalidEncoding,
              'Could not read foo.dat because the file is not valid UTF-16.',
            )
        end
      end
    end

    context 'file exists as UTF-8 wit BOM' do
      before do
        File.write(filename, "\xEF\xBB\xBFélève".encode('UTF-8'))
      end

      it { is_expected.to eq('élève') }
      its(:encoding) { is_expected.to eq(Encoding::UTF_8) }
    end
  end
end
