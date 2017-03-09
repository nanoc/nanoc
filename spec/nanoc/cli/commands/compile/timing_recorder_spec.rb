describe Nanoc::CLI::Commands::Compile::TimingRecorder, stdio: true do
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

  it 'records single from filtering_started to filtering_ended' do
    listener.start

    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :erb)

    expect { listener.stop }
      .to output(/^erb │     1   1\.00s   1\.00s   1\.00s   1\.00s$/).to_stdout
  end

  it 'records multiple from filtering_started to filtering_ended' do
    listener.start

    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 14, 1))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 14, 3))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :erb)

    expect { listener.stop }
      .to output(/^erb │     2   1\.00s   1\.50s   2\.00s   3\.00s$/).to_stdout
  end

  it 'records single from filtering_started over compilation_{suspended,started} to filtering_ended' do
    listener.start

    Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:compilation_suspended, rep, :__anything__)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 3))
    Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 7))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :erb)

    expect { listener.stop }
      .to output(/^erb │     1   5\.00s   5\.00s   5\.00s   5\.00s$/).to_stdout
  end
end
