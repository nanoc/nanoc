# frozen_string_literal: true

describe Nanoc::CLI::Commands::CompileListeners::FileActionPrinter, stdio: true do
  let(:listener) { described_class.new(reps: reps) }

  before { Timecop.freeze(Time.local(2008, 1, 2, 14, 5, 0)) }
  after { Timecop.return }

  let(:reps) do
    Nanoc::Int::ItemRepRepo.new.tap do |reps|
      reps << rep
    end
  end

  let(:item) { Nanoc::Int::Item.new('<%= 1 + 2 %>', {}, '/hi.md') }

  let(:rep) do
    Nanoc::Int::ItemRep.new(item, :default).tap do |rep|
      rep.raw_paths = { default: ['/hi.html'] }
    end
  end

  it 'records from compilation_started to rep_written' do
    listener.start

    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))

    expect { Nanoc::Int::NotificationCenter.post(:rep_written, rep, false, '/foo.html', true, true) }
      .to output(/create.*\[1\.00s\]/).to_stdout
  end

  it 'stops listening after #stop' do
    listener.start
    listener.stop

    Nanoc::Int::NotificationCenter.post(:compilation_started, rep)

    expect { Nanoc::Int::NotificationCenter.post(:rep_written, rep, false, '/foo.html', true, true) }
      .not_to output(/create/).to_stdout
  end

  it 'records from compilation_started over compilation_suspended to rep_written' do
    listener.start

    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:compilation_suspended, rep, :__irrelevant__)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 3))
    Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 6))

    expect { Nanoc::Int::NotificationCenter.post(:rep_written, rep, false, '/foo.html', true, true) }
      .to output(/create.*\[4\.00s\]/).to_stdout
  end

  context 'log level = high' do
    before { listener.start }
    before { Nanoc::CLI::Logger.instance.level = :high }

    it 'prints skipped (uncompiled) reps' do
      expect { listener.stop }
        .not_to output(/skip/).to_stdout
    end
  end

  context 'log level = low' do
    before { listener.start }
    before { Nanoc::CLI::Logger.instance.level = :low }

    it 'prints nothing' do
      expect { listener.stop }
        .to output(/skip.*\/hi\.html/).to_stdout
    end
  end
end
