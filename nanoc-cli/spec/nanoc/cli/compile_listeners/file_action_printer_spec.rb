# frozen_string_literal: true

describe Nanoc::CLI::CompileListeners::FileActionPrinter, stdio: true do
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
      .and_return(original_timestamp + seconds * 1_000_000_000)
  end

  after do
    listener.stop_safely
  end

  it 'records from compilation_started to rep_write_ended' do
    listener.start_safely

    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
    mock_time(1)

    expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', true, true).sync }
      .to output(/create.*\[1\.00s\]/).to_stdout
  end

  it 'stops listening after #stop' do
    listener.start_safely
    listener.stop_safely

    Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync

    expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', true, true).sync }
      .not_to output(/create/).to_stdout
  end

  it 'records from compilation_started over compilation_suspended to rep_write_ended' do
    listener.start_safely

    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:compilation_suspended, rep, :__irrelevant__).sync
    mock_time(3)
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
    mock_time(6)

    expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', true, true).sync }
      .to output(/create.*\[4\.00s\]/).to_stdout
  end

  it 'records from compilation_started over rep_write_{enqueued,started} to rep_write_ended' do
    listener.start_safely

    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:rep_write_enqueued, rep).sync
    mock_time(3)
    Nanoc::Core::NotificationCenter.post(:rep_write_started, rep).sync
    mock_time(6)

    expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', true, true).sync }
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

    it 'prints nothing' do
      Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
      mock_time(1)

      expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', false, false).sync }
        .not_to output(/identical/).to_stdout
    end

    it 'prints nothing' do
      Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
      Nanoc::Core::NotificationCenter.post(:cached_content_used, rep).sync
      mock_time(1)

      expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', false, false).sync }
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
        .to output(/skip.*\/hi\.html/).to_stdout
    end

    it 'prints “identical” if not cached' do
      Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
      mock_time(1)

      expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', false, false).sync }
        .to output(/identical/).to_stdout
    end

    it 'prints “cached” if cached' do
      Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
      Nanoc::Core::NotificationCenter.post(:cached_content_used, rep).sync
      mock_time(1)

      expect { Nanoc::Core::NotificationCenter.post(:rep_write_ended, rep, false, '/foo.html', false, false).sync }
        .to output(/cached/).to_stdout
    end
  end
end
