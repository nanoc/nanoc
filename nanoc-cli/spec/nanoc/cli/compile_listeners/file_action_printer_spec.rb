# frozen_string_literal: true

describe Nanoc::CLI::CompileListeners::FileActionPrinter, :stdio do
  let(:listener) { described_class.new(reps:) }
  let(:reps) do
    Nanoc::Core::ItemRepRepo.new.tap do |reps|
      reps << rep
    end
  end
  let(:item) { Nanoc::Core::Item.new('<%= 1 + 2 %>', {}, '/hi.md') }
  let(:rep) do
    Nanoc::Core::ItemRep.new(item, :default).tap do |rep|
      rep.raw_paths = { default: ['/hi.html'] }
    end
  end

  let(:original_timestamp) { Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond) }

  def mock_time(seconds)
    allow(Process)
      .to receive(:clock_gettime)
      .with(Process::CLOCK_MONOTONIC, :nanosecond)
      .and_return(original_timestamp + (seconds * 1_000_000_000))
  end

  after do
    listener.stop_safely
  end

  it 'records from compilation_started to rep_write_ended' do
    listener.start_safely

    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep)
    mock_time(1)

    expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', true, true) }
      .to output(/create.*\[1\.00s\]/).to_stdout
  end

  it 'stops listening after #stop' do
    listener.start_safely
    listener.stop_safely

    Nanoc::Core::NotificationCenter.post(:compilation_started, rep)

    expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', true, true) }
      .not_to output(/create/).to_stdout
  end

  it 'records from compilation_started over compilation_suspended to rep_write_ended' do
    listener.start_safely

    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep)
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:compilation_suspended, rep, :__irrelevant__)
    mock_time(3)
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep)
    mock_time(6)

    expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', true, true) }
      .to output(/create.*\[4\.00s\]/).to_stdout
  end

  it 'records from compilation_started over rep_write_{enqueued,started} to rep_write_ended' do
    listener.start_safely

    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep)
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:rep_write_enqueued, rep)
    mock_time(3)
    Nanoc::Core::NotificationCenter.post(:rep_write_started, rep)
    mock_time(6)

    expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', true, true) }
      .to output(/create.*\[4\.00s\]/).to_stdout
  end

  context 'log level = high' do
    before do
      listener.start_safely
      Nanoc::CLI::Logger.instance.level = :high
    end

    it 'does not print skipped (uncompiled) reps' do
      expect { listener.stop_safely }
        .not_to output(/skip/).to_stdout
    end

    it 'prints nothing after compilation_started' do
      Nanoc::Core::NotificationCenter.post(:compilation_started, rep)
      mock_time(1)

      expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', false, false) }
        .not_to output(/identical/).to_stdout
    end

    it 'prints nothing after compilation_started and cached_content_used' do
      Nanoc::Core::NotificationCenter.post(:compilation_started, rep)
      Nanoc::Core::NotificationCenter.post(:cached_content_used, rep)
      mock_time(1)

      expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', false, false) }
        .not_to output(/cached/).to_stdout
    end
  end

  context 'log level = low' do
    before do
      listener.start_safely
      Nanoc::CLI::Logger.instance.level = :low
    end

    it 'prints skipped (uncompiled) reps' do
      expect { listener.stop_safely }
        .to output(%r{skip.*/hi\.html}).to_stdout
    end

    it 'prints “identical” if not cached' do
      Nanoc::Core::NotificationCenter.post(:compilation_started, rep)
      mock_time(1)

      expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', false, false) }
        .to output(/identical/).to_stdout
    end

    it 'prints “cached” if cached' do
      Nanoc::Core::NotificationCenter.post(:compilation_started, rep)
      Nanoc::Core::NotificationCenter.post(:cached_content_used, rep)
      mock_time(1)

      expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', false, false) }
        .to output(/cached/).to_stdout
    end
  end
end
