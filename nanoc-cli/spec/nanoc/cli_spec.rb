# frozen_string_literal: true

describe Nanoc::CLI do
  it 'enables UTF-8 only on TTYs' do
    new_env_diff = {
      'LC_ALL' => 'en_US.ISO-8859-1',
      'LC_CTYPE' => 'en_US.ISO-8859-1',
      'LANG' => 'en_US.ISO-8859-1',
    }
    __nanoc_core_with_env_vars(new_env_diff) do
      io = StringIO.new
      def io.tty?
        true
      end
      expect(described_class.enable_utf8?(io)).not_to be

      io = StringIO.new
      def io.tty?
        false
      end
      expect(described_class.enable_utf8?(io)).to be
    end
  end

  it 'enables UTF-8 when appropriate' do
    io = StringIO.new
    def io.tty?
      true
    end

    new_env_diff = {
      'LC_ALL' => 'en_US.ISO-8859-1',
      'LC_CTYPE' => 'en_US.ISO-8859-1',
      'LANG' => 'en_US.ISO-8859-1',
    }
    __nanoc_core_with_env_vars(new_env_diff) do
      expect(described_class.enable_utf8?(io)).not_to be

      __nanoc_core_with_env_vars('LC_ALL'   => 'en_US.UTF-8') { expect(described_class.enable_utf8?(io)).to be }
      __nanoc_core_with_env_vars('LC_CTYPE' => 'en_US.UTF-8') { expect(described_class.enable_utf8?(io)).to be }
      __nanoc_core_with_env_vars('LANG'     => 'en_US.UTF-8') { expect(described_class.enable_utf8?(io)).to be }

      __nanoc_core_with_env_vars('LC_ALL'   => 'en_US.utf-8') { expect(described_class.enable_utf8?(io)).to be }
      __nanoc_core_with_env_vars('LC_CTYPE' => 'en_US.utf-8') { expect(described_class.enable_utf8?(io)).to be }
      __nanoc_core_with_env_vars('LANG'     => 'en_US.utf-8') { expect(described_class.enable_utf8?(io)).to be }

      __nanoc_core_with_env_vars('LC_ALL'   => 'en_US.utf8') { expect(described_class.enable_utf8?(io)).to be }
      __nanoc_core_with_env_vars('LC_CTYPE' => 'en_US.utf8') { expect(described_class.enable_utf8?(io)).to be }
      __nanoc_core_with_env_vars('LANG'     => 'en_US.utf8') { expect(described_class.enable_utf8?(io)).to be }
    end
  end

  describe '#enable_ansi_colors?' do
    subject { described_class.enable_ansi_colors?(io) }

    context 'TTY' do
      let(:io) { double(:io, tty?: true) }

      context 'NO_COLOR set' do
        before do
          allow(ENV).to receive(:key?).with('NO_COLOR').and_return(true)
        end

        it { is_expected.to be(false) }
      end

      context 'NO_COLOR not set' do
        it { is_expected.to be(true) }
      end
    end

    context 'no TTY' do
      let(:io) { double(:io, tty?: false) }

      context 'NO_COLOR set' do
        before do
          allow(ENV).to receive(:key?).with('NO_COLOR').and_return(true)
        end

        it { is_expected.to be(false) }
      end

      context 'NO_COLOR not set' do
        it { is_expected.to be(false) }
      end
    end
  end
end
