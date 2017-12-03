# frozen_string_literal: true

describe Nanoc::CLI::Commands::CompileListeners::TimingRecorder, stdio: true do
  let(:listener) { described_class.new(reps: reps) }

  before { Timecop.freeze(Time.local(2008, 1, 2, 14, 5, 0)) }
  after { Timecop.return }

  before { Nanoc::CLI.verbosity = 2 }

  before { listener.start }
  after { listener.stop_safely }

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

  let(:other_rep) do
    Nanoc::Int::ItemRep.new(item, :other).tap do |rep|
      rep.raw_paths = { default: ['/bye.html'] }
    end
  end

  it 'prints filters table' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 14, 1))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 14, 3))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :erb)

    expect { listener.stop }
      .to output(/^\s*erb │     2   1\.00s   1\.50s   1\.90s   1\.95s   2\.00s   3\.00s$/).to_stdout
  end

  it 'records single from filtering_started to filtering_ended' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :erb)

    expect(listener.telemetry.summary(:filters).get('erb').min).to eq(1.00)
    expect(listener.telemetry.summary(:filters).get('erb').avg).to eq(1.00)
    expect(listener.telemetry.summary(:filters).get('erb').max).to eq(1.00)
    expect(listener.telemetry.summary(:filters).get('erb').sum).to eq(1.00)
    expect(listener.telemetry.summary(:filters).get('erb').count).to eq(1.00)
  end

  it 'records multiple from filtering_started to filtering_ended' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 14, 1))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 14, 3))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :erb)

    expect(listener.telemetry.summary(:filters).get('erb').min).to eq(1.00)
    expect(listener.telemetry.summary(:filters).get('erb').avg).to eq(1.50)
    expect(listener.telemetry.summary(:filters).get('erb').max).to eq(2.00)
    expect(listener.telemetry.summary(:filters).get('erb').sum).to eq(3.00)
    expect(listener.telemetry.summary(:filters).get('erb').count).to eq(2.00)
  end

  it 'records filters in nested filtering_started/filtering_ended' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :outer)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :inner)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 3))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :inner)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 6))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :outer)

    expect(listener.telemetry.summary(:filters).get('inner').min).to eq(2.00)
    expect(listener.telemetry.summary(:filters).get('inner').avg).to eq(2.00)
    expect(listener.telemetry.summary(:filters).get('inner').max).to eq(2.00)
    expect(listener.telemetry.summary(:filters).get('inner').sum).to eq(2.00)
    expect(listener.telemetry.summary(:filters).get('inner').count).to eq(1.00)

    expect(listener.telemetry.summary(:filters).get('outer').min).to eq(6.00)
    expect(listener.telemetry.summary(:filters).get('outer').avg).to eq(6.00)
    expect(listener.telemetry.summary(:filters).get('outer').max).to eq(6.00)
    expect(listener.telemetry.summary(:filters).get('outer').sum).to eq(6.00)
    expect(listener.telemetry.summary(:filters).get('outer').count).to eq(1.00)
  end

  it 'pauses outer stopwatch when suspended' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :outer)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :inner)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 3))
    Nanoc::Int::NotificationCenter.post(:compilation_suspended, rep, :__anything__)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 6))
    Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 10))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :inner)
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :outer)

    expect(listener.telemetry.summary(:filters).get('outer').min).to eq(7.00)
    expect(listener.telemetry.summary(:filters).get('outer').avg).to eq(7.00)
    expect(listener.telemetry.summary(:filters).get('outer').max).to eq(7.00)
    expect(listener.telemetry.summary(:filters).get('outer').sum).to eq(7.00)
    expect(listener.telemetry.summary(:filters).get('outer').count).to eq(1.00)
  end

  it 'records single from filtering_started over compilation_{suspended,started} to filtering_ended' do
    Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:filtering_started, rep, :erb)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:compilation_suspended, rep, :__anything__)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 3))
    Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 7))
    Nanoc::Int::NotificationCenter.post(:filtering_ended, rep, :erb)

    expect(listener.telemetry.summary(:filters).get('erb').min).to eq(5.00)
    expect(listener.telemetry.summary(:filters).get('erb').avg).to eq(5.00)
    expect(listener.telemetry.summary(:filters).get('erb').max).to eq(5.00)
    expect(listener.telemetry.summary(:filters).get('erb').sum).to eq(5.00)
    expect(listener.telemetry.summary(:filters).get('erb').count).to eq(1.00)
  end

  it 'records single phase start+stop' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:phase_started, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:phase_ended, 'donkey', rep)

    expect(listener.telemetry.summary(:phases).get('donkey').min).to eq(1.00)
    expect(listener.telemetry.summary(:phases).get('donkey').avg).to eq(1.00)
    expect(listener.telemetry.summary(:phases).get('donkey').max).to eq(1.00)
    expect(listener.telemetry.summary(:phases).get('donkey').sum).to eq(1.00)
    expect(listener.telemetry.summary(:phases).get('donkey').count).to eq(1.00)
  end

  it 'records multiple phase start+stop' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:phase_started, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:phase_ended, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 11, 6, 0))
    Nanoc::Int::NotificationCenter.post(:phase_started, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 11, 6, 2))
    Nanoc::Int::NotificationCenter.post(:phase_ended, 'donkey', rep)

    expect(listener.telemetry.summary(:phases).get('donkey').min).to eq(1.00)
    expect(listener.telemetry.summary(:phases).get('donkey').avg).to eq(1.50)
    expect(listener.telemetry.summary(:phases).get('donkey').max).to eq(2.00)
    expect(listener.telemetry.summary(:phases).get('donkey').sum).to eq(3.00)
    expect(listener.telemetry.summary(:phases).get('donkey').count).to eq(2.00)
  end

  it 'records single phase start+yield+resume+stop' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:phase_started, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:phase_yielded, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 11, 6, 0))
    Nanoc::Int::NotificationCenter.post(:phase_resumed, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 11, 6, 2))
    Nanoc::Int::NotificationCenter.post(:phase_ended, 'donkey', rep)

    expect(listener.telemetry.summary(:phases).get('donkey').min).to eq(3.00)
    expect(listener.telemetry.summary(:phases).get('donkey').avg).to eq(3.00)
    expect(listener.telemetry.summary(:phases).get('donkey').max).to eq(3.00)
    expect(listener.telemetry.summary(:phases).get('donkey').sum).to eq(3.00)
    expect(listener.telemetry.summary(:phases).get('donkey').count).to eq(1.00)
  end

  it 'records single phase start+yield+abort+start+stop' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:phase_started, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:phase_yielded, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 11, 6, 0))
    Nanoc::Int::NotificationCenter.post(:phase_aborted, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 12, 7, 2))
    Nanoc::Int::NotificationCenter.post(:phase_started, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 12, 7, 5))
    Nanoc::Int::NotificationCenter.post(:phase_ended, 'donkey', rep)

    expect(listener.telemetry.summary(:phases).get('donkey').min).to eq(1.00)
    expect(listener.telemetry.summary(:phases).get('donkey').avg).to eq(2.00)
    expect(listener.telemetry.summary(:phases).get('donkey').max).to eq(3.00)
    expect(listener.telemetry.summary(:phases).get('donkey').sum).to eq(4.00)
    expect(listener.telemetry.summary(:phases).get('donkey').count).to eq(2.00)
  end

  it 'records stage duration' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:stage_started, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:stage_ended, 'donkey', rep)

    expect(listener.telemetry.summary(:stages).get('donkey').sum).to eq(1.00)
    expect(listener.telemetry.summary(:stages).get('donkey').count).to eq(1.00)
  end

  it 'prints stage durations' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:stage_started, 'donkey', rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:stage_ended, 'donkey', rep)

    expect { listener.stop }
      .to output(/^\s*donkey │ 1\.00s$/).to_stdout
  end

  it 'prints out outdatedness rule durations' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:outdatedness_rule_started, Nanoc::Int::OutdatednessRules::CodeSnippetsModified, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:outdatedness_rule_ended, Nanoc::Int::OutdatednessRules::CodeSnippetsModified, rep)

    expect { listener.stop }
      .to output(/^\s*CodeSnippetsModified │     1   1\.00s   1\.00s   1\.00s   1\.00s   1\.00s   1\.00s$/).to_stdout
  end

  it 'records single outdatedness rule duration' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:outdatedness_rule_started, Nanoc::Int::OutdatednessRules::CodeSnippetsModified, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:outdatedness_rule_ended, Nanoc::Int::OutdatednessRules::CodeSnippetsModified, rep)

    expect(listener.telemetry.summary(:outdatedness_rules).get('CodeSnippetsModified').min).to eq(1.00)
    expect(listener.telemetry.summary(:outdatedness_rules).get('CodeSnippetsModified').avg).to eq(1.00)
    expect(listener.telemetry.summary(:outdatedness_rules).get('CodeSnippetsModified').max).to eq(1.00)
    expect(listener.telemetry.summary(:outdatedness_rules).get('CodeSnippetsModified').sum).to eq(1.00)
    expect(listener.telemetry.summary(:outdatedness_rules).get('CodeSnippetsModified').count).to eq(1.00)
  end

  it 'records multiple outdatedness rule duration' do
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 0))
    Nanoc::Int::NotificationCenter.post(:outdatedness_rule_started, Nanoc::Int::OutdatednessRules::CodeSnippetsModified, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 5, 1))
    Nanoc::Int::NotificationCenter.post(:outdatedness_rule_ended, Nanoc::Int::OutdatednessRules::CodeSnippetsModified, rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 6, 0))
    Nanoc::Int::NotificationCenter.post(:outdatedness_rule_started, Nanoc::Int::OutdatednessRules::CodeSnippetsModified, other_rep)
    Timecop.freeze(Time.local(2008, 9, 1, 10, 6, 3))
    Nanoc::Int::NotificationCenter.post(:outdatedness_rule_ended, Nanoc::Int::OutdatednessRules::CodeSnippetsModified, other_rep)

    expect(listener.telemetry.summary(:outdatedness_rules).get('CodeSnippetsModified').min).to eq(1.00)
    expect(listener.telemetry.summary(:outdatedness_rules).get('CodeSnippetsModified').avg).to eq(2.00)
    expect(listener.telemetry.summary(:outdatedness_rules).get('CodeSnippetsModified').max).to eq(3.00)
    expect(listener.telemetry.summary(:outdatedness_rules).get('CodeSnippetsModified').sum).to eq(4.00)
    expect(listener.telemetry.summary(:outdatedness_rules).get('CodeSnippetsModified').count).to eq(2.00)
  end

  it 'records memoization usage' do
    Nanoc::Int::NotificationCenter.post(:memoization_hit, 'Foo#bar', rep)
    Nanoc::Int::NotificationCenter.post(:memoization_miss, 'Foo#bar', rep)
    Nanoc::Int::NotificationCenter.post(:memoization_miss, 'Foo#bar', rep)
    Nanoc::Int::NotificationCenter.post(:memoization_miss, 'Foo#bar', rep)
    Nanoc::Int::NotificationCenter.post(:memoization_miss, 'Foo#bar', rep)

    expect(listener.telemetry.counter(:memoization).get(['Foo#bar', :hit]).value).to eq(1)
    expect(listener.telemetry.counter(:memoization).get(['Foo#bar', :miss]).value).to eq(4)
  end

  it 'prints memoization table' do
    Nanoc::Int::NotificationCenter.post(:memoization_hit, 'Foo#bar', rep)
    Nanoc::Int::NotificationCenter.post(:memoization_miss, 'Foo#bar', rep)
    Nanoc::Int::NotificationCenter.post(:memoization_miss, 'Foo#bar', rep)
    Nanoc::Int::NotificationCenter.post(:memoization_miss, 'Foo#bar', rep)
    Nanoc::Int::NotificationCenter.post(:memoization_miss, 'Foo#bar', rep)

    expect { listener.stop }
      .to output(/^\s*Foo#bar │   1      4   20\.0%$/).to_stdout
  end
end
