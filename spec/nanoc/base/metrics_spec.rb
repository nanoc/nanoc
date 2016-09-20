describe Nanoc::Metrics::EventCreator do
  subject(:event_creator) { described_class.new }
end

describe Nanoc::Metrics::EventQueue do
  subject(:event_queue) { described_class.new(sender: event_sender) }

  let(:fake_event_sender_class) do
    Class.new do
      attr_reader :sent_events

      def initalize
        @sent_events = []
      end

      def send_sync(event)
        @sent_events << event
      end
    end
  end

  let(:event_sender) { fake_event_sender_class.new }

  example do
    event_queue << Nanoc::Metrics::EventCreator.new.new_started_event
    expect(event_queue.sent_events.size).to eq(1)
  end
end
