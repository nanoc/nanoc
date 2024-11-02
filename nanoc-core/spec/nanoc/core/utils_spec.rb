# frozen_string_literal: true

describe Nanoc::Core::Utils do
  describe '.expand_path_without_drive_identifier' do
    # TODO: Test on Windows

    subject { described_class.expand_path_without_drive_identifier('foo.html', '/home/denis') }

    it { is_expected.to eq('/home/denis/foo.html') }
  end
end
