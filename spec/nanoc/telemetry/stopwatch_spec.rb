# frozen_string_literal: true

describe Nanoc::Telemetry::Stopwatch do
  subject(:stopwatch) { described_class.new }

  after { Timecop.return }

  it 'is zero by default' do
    expect(stopwatch.duration).to eq(0.0)
  end

  # TODO: if running, raise error when asking for #duration

  it 'records correct duration after start+stop' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    stopwatch.start

    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    stopwatch.stop

    expect(stopwatch.duration).to eq(1.0)
  end

  it 'records correct duration after start+stop+start+stop' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    stopwatch.start

    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    stopwatch.stop

    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 3))
    stopwatch.start

    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 6))
    stopwatch.stop

    expect(stopwatch.duration).to eq(1.0 + 3.0)
  end

  it 'errors when stopping when not started' do
    expect { stopwatch.stop }.to raise_error(Nanoc::Telemetry::Stopwatch::NotRunningError)
  end

  it 'errors when starting when already started' do
    stopwatch.start
    expect { stopwatch.start }.to raise_error(Nanoc::Telemetry::Stopwatch::AlreadyRunningError)
  end

  it 'reports running status' do
    expect(stopwatch).not_to be_running
    expect(stopwatch).to be_stopped

    stopwatch.start

    expect(stopwatch).to be_running
    expect(stopwatch).not_to be_stopped

    stopwatch.stop

    expect(stopwatch).not_to be_running
    expect(stopwatch).to be_stopped
  end
end
