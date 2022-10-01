# frozen_string_literal: true

describe(Nanoc::Core::Instrumentor) do
  subject { described_class }

  before { Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0)) }

  after { Timecop.return }

  context 'when not enabled (i.e. by default)' do
    it 'does not send notification' do
      expect do
        subject.call(:sample_notification, 'garbage', 123) do
          # Go to a few seconds in the future
          Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 5))
        end
      end.not_to send_notification(:sample_notification, 5.0, 'garbage', 123)
    end
  end

  context 'when enabled' do
    around do |ex|
      described_class.enable { ex.run }
    end

    it 'sends notification' do
      expect do
        subject.call(:sample_notification, 'garbage', 123) do
          # Go to a few seconds in the future
          Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 5))
        end
      end.to send_notification(:sample_notification, 5.0, 'garbage', 123)
    end
  end
end
