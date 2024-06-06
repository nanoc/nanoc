# frozen_string_literal: true

describe Nanoc::CLI::CompileListeners::TimingRecorder, stdio: true do
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
  let(:other_rep) do
    Nanoc::Core::ItemRep.new(item, :other).tap do |rep|
      rep.raw_paths = { default: ['/bye.html'] }
    end
  end

  let(:original_timestamp) { Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond) }

  def mock_time(seconds)
    allow(Process)
      .to receive(:clock_gettime)
      .with(Process::CLOCK_MONOTONIC, :nanosecond)
      .and_return(original_timestamp + seconds * 1_000_000_000)
  end

  before do
    Nanoc::CLI.verbosity = 2
    listener.start_safely
  end

  after do
    listener.stop_safely
  end

  it 'prints filters table' do
    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:filtering_started, rep, :erb).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:filtering_ended, rep, :erb).sync
    mock_time(100)
    Nanoc::Core::NotificationCenter.post(:filtering_started, rep, :erb).sync
    mock_time(102)
    Nanoc::Core::NotificationCenter.post(:filtering_ended, rep, :erb).sync

    expect { listener.stop_safely }
      .to output(/^\s*erb │     2   1\.00s   1\.50s   1\.90s   1\.95s   2\.00s   3\.00s$/).to_stdout
  end

  it 'records single from filtering_started to filtering_ended' do
    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:filtering_started, rep, :erb).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:filtering_ended, rep, :erb).sync

    expect(listener.filters_summary.get(name: 'erb').min).to eq(1.00)
    expect(listener.filters_summary.get(name: 'erb').avg).to eq(1.00)
    expect(listener.filters_summary.get(name: 'erb').max).to eq(1.00)
    expect(listener.filters_summary.get(name: 'erb').sum).to eq(1.00)
    expect(listener.filters_summary.get(name: 'erb').count).to eq(1.00)
  end

  it 'records multiple from filtering_started to filtering_ended' do
    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:filtering_started, rep, :erb).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:filtering_ended, rep, :erb).sync
    mock_time(100)
    Nanoc::Core::NotificationCenter.post(:filtering_started, rep, :erb).sync
    mock_time(102)
    Nanoc::Core::NotificationCenter.post(:filtering_ended, rep, :erb).sync

    expect(listener.filters_summary.get(name: 'erb').min).to eq(1.00)
    expect(listener.filters_summary.get(name: 'erb').avg).to eq(1.50)
    expect(listener.filters_summary.get(name: 'erb').max).to eq(2.00)
    expect(listener.filters_summary.get(name: 'erb').sum).to eq(3.00)
    expect(listener.filters_summary.get(name: 'erb').count).to eq(2.00)
  end

  it 'records filters in nested filtering_started/filtering_ended' do
    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:filtering_started, rep, :outer).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:filtering_started, rep, :inner).sync
    mock_time(3)
    Nanoc::Core::NotificationCenter.post(:filtering_ended, rep, :inner).sync
    mock_time(6)
    Nanoc::Core::NotificationCenter.post(:filtering_ended, rep, :outer).sync

    expect(listener.filters_summary.get(name: 'inner').min).to eq(2.00)
    expect(listener.filters_summary.get(name: 'inner').avg).to eq(2.00)
    expect(listener.filters_summary.get(name: 'inner').max).to eq(2.00)
    expect(listener.filters_summary.get(name: 'inner').sum).to eq(2.00)
    expect(listener.filters_summary.get(name: 'inner').count).to eq(1.00)

    expect(listener.filters_summary.get(name: 'outer').min).to eq(6.00)
    expect(listener.filters_summary.get(name: 'outer').avg).to eq(6.00)
    expect(listener.filters_summary.get(name: 'outer').max).to eq(6.00)
    expect(listener.filters_summary.get(name: 'outer').sum).to eq(6.00)
    expect(listener.filters_summary.get(name: 'outer').count).to eq(1.00)
  end

  it 'pauses outer stopwatch when suspended' do
    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
    Nanoc::Core::NotificationCenter.post(:filtering_started, rep, :outer).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:filtering_started, rep, :inner).sync
    mock_time(3)
    Nanoc::Core::NotificationCenter.post(:compilation_suspended, rep, :__anything__).sync
    mock_time(6)
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
    mock_time(10)
    Nanoc::Core::NotificationCenter.post(:filtering_ended, rep, :inner).sync
    Nanoc::Core::NotificationCenter.post(:filtering_ended, rep, :outer).sync

    expect(listener.filters_summary.get(name: 'outer').min).to eq(7.00)
    expect(listener.filters_summary.get(name: 'outer').avg).to eq(7.00)
    expect(listener.filters_summary.get(name: 'outer').max).to eq(7.00)
    expect(listener.filters_summary.get(name: 'outer').sum).to eq(7.00)
    expect(listener.filters_summary.get(name: 'outer').count).to eq(1.00)
  end

  it 'records single from filtering_started over compilation_{suspended,started} to filtering_ended' do
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:filtering_started, rep, :erb).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:compilation_suspended, rep, :__anything__).sync
    mock_time(3)
    Nanoc::Core::NotificationCenter.post(:compilation_started, rep).sync
    mock_time(7)
    Nanoc::Core::NotificationCenter.post(:filtering_ended, rep, :erb).sync

    expect(listener.filters_summary.get(name: 'erb').min).to eq(5.00)
    expect(listener.filters_summary.get(name: 'erb').avg).to eq(5.00)
    expect(listener.filters_summary.get(name: 'erb').max).to eq(5.00)
    expect(listener.filters_summary.get(name: 'erb').sum).to eq(5.00)
    expect(listener.filters_summary.get(name: 'erb').count).to eq(1.00)
  end

  it 'records single phase start+stop' do
    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:phase_started, 'donkey', rep).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:phase_ended, 'donkey', rep).sync

    expect(listener.phases_summary.get(name: 'donkey').min).to eq(1.00)
    expect(listener.phases_summary.get(name: 'donkey').avg).to eq(1.00)
    expect(listener.phases_summary.get(name: 'donkey').max).to eq(1.00)
    expect(listener.phases_summary.get(name: 'donkey').sum).to eq(1.00)
    expect(listener.phases_summary.get(name: 'donkey').count).to eq(1.00)
  end

  it 'records multiple phase start+stop' do
    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:phase_started, 'donkey', rep).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:phase_ended, 'donkey', rep).sync
    mock_time(100)
    Nanoc::Core::NotificationCenter.post(:phase_started, 'donkey', rep).sync
    mock_time(102)
    Nanoc::Core::NotificationCenter.post(:phase_ended, 'donkey', rep).sync

    expect(listener.phases_summary.get(name: 'donkey').min).to eq(1.00)
    expect(listener.phases_summary.get(name: 'donkey').avg).to eq(1.50)
    expect(listener.phases_summary.get(name: 'donkey').max).to eq(2.00)
    expect(listener.phases_summary.get(name: 'donkey').sum).to eq(3.00)
    expect(listener.phases_summary.get(name: 'donkey').count).to eq(2.00)
  end

  it 'records single phase start+yield+resume+stop' do
    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:phase_started, 'donkey', rep).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:phase_yielded, 'donkey', rep).sync
    mock_time(100)
    Nanoc::Core::NotificationCenter.post(:phase_resumed, 'donkey', rep).sync
    mock_time(102)
    Nanoc::Core::NotificationCenter.post(:phase_ended, 'donkey', rep).sync

    expect(listener.phases_summary.get(name: 'donkey').min).to eq(3.00)
    expect(listener.phases_summary.get(name: 'donkey').avg).to eq(3.00)
    expect(listener.phases_summary.get(name: 'donkey').max).to eq(3.00)
    expect(listener.phases_summary.get(name: 'donkey').sum).to eq(3.00)
    expect(listener.phases_summary.get(name: 'donkey').count).to eq(1.00)
  end

  it 'records single phase start+yield+abort+start+stop' do
    mock_time(0)
    Nanoc::Core::NotificationCenter.post(:phase_started, 'donkey', rep).sync
    mock_time(1)
    Nanoc::Core::NotificationCenter.post(:phase_yielded, 'donkey', rep).sync
    mock_time(100)
    Nanoc::Core::NotificationCenter.post(:phase_aborted, 'donkey', rep).sync
    mock_time(200)
    Nanoc::Core::NotificationCenter.post(:phase_started, 'donkey', rep).sync
    mock_time(203)
    Nanoc::Core::NotificationCenter.post(:phase_ended, 'donkey', rep).sync

    expect(listener.phases_summary.get(name: 'donkey').min).to eq(1.00)
    expect(listener.phases_summary.get(name: 'donkey').avg).to eq(2.00)
    expect(listener.phases_summary.get(name: 'donkey').max).to eq(3.00)
    expect(listener.phases_summary.get(name: 'donkey').sum).to eq(4.00)
    expect(listener.phases_summary.get(name: 'donkey').count).to eq(2.00)
  end

  it 'records stage duration' do
    Nanoc::Core::NotificationCenter.post(:stage_ran, 1.23, 'donkey_stage').sync

    expect(listener.stages_summary.get(name: 'donkey_stage').sum).to eq(1.23)
    expect(listener.stages_summary.get(name: 'donkey_stage').count).to eq(1)
  end

  it 'prints stage durations' do
    Nanoc::Core::NotificationCenter.post(:stage_ran, 1.23, 'donkey_stage').sync

    expect { listener.stop_safely }
      .to output(/^\s*donkey_stage │ 1\.23s$/).to_stdout
  end

  it 'prints out outdatedness rule durations' do
    Nanoc::Core::NotificationCenter.post(:outdatedness_rule_ran, 1.0, Nanoc::Core::OutdatednessRules::CodeSnippetsModified).sync

    expect { listener.stop_safely }
      .to output(/^\s*CodeSnippetsModified │     1   1\.00s   1\.00s   1\.00s   1\.00s   1\.00s   1\.00s$/).to_stdout
  end

  it 'records single outdatedness rule duration' do
    Nanoc::Core::NotificationCenter.post(:outdatedness_rule_ran, 1.0, Nanoc::Core::OutdatednessRules::CodeSnippetsModified).sync

    expect(listener.outdatedness_rules_summary.get(name: 'CodeSnippetsModified').min).to eq(1.00)
    expect(listener.outdatedness_rules_summary.get(name: 'CodeSnippetsModified').avg).to eq(1.00)
    expect(listener.outdatedness_rules_summary.get(name: 'CodeSnippetsModified').max).to eq(1.00)
    expect(listener.outdatedness_rules_summary.get(name: 'CodeSnippetsModified').sum).to eq(1.00)
    expect(listener.outdatedness_rules_summary.get(name: 'CodeSnippetsModified').count).to eq(1.00)
  end

  it 'records multiple outdatedness rule duration' do
    Nanoc::Core::NotificationCenter.post(:outdatedness_rule_ran, 1.0, Nanoc::Core::OutdatednessRules::CodeSnippetsModified).sync
    Nanoc::Core::NotificationCenter.post(:outdatedness_rule_ran, 3.0, Nanoc::Core::OutdatednessRules::CodeSnippetsModified).sync

    expect(listener.outdatedness_rules_summary.get(name: 'CodeSnippetsModified').min).to eq(1.00)
    expect(listener.outdatedness_rules_summary.get(name: 'CodeSnippetsModified').avg).to eq(2.00)
    expect(listener.outdatedness_rules_summary.get(name: 'CodeSnippetsModified').max).to eq(3.00)
    expect(listener.outdatedness_rules_summary.get(name: 'CodeSnippetsModified').sum).to eq(4.00)
    expect(listener.outdatedness_rules_summary.get(name: 'CodeSnippetsModified').count).to eq(2.00)
  end

  it 'prints load store durations' do
    Nanoc::Core::NotificationCenter.post(:store_loaded, 1.23, Nanoc::Core::ChecksumStore).sync

    expect { listener.stop_safely }
      .to output(/^\s*Nanoc::Core::ChecksumStore │ 1\.23s$/).to_stdout
  end

  it 'prints store store durations' do
    Nanoc::Core::NotificationCenter.post(:store_stored, 2.34, Nanoc::Core::ChecksumStore).sync

    expect { listener.stop_safely }
      .to output(/^\s*Nanoc::Core::ChecksumStore │ 2\.34s$/).to_stdout
  end

  it 'skips printing empty metrics' do
    expect { listener.stop_safely }
      .not_to output(/filters|phases|stages/).to_stdout
  end
end
