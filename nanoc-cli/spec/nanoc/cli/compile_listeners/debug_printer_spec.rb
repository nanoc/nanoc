# frozen_string_literal: true

describe Nanoc::CLI::CompileListeners::DebugPrinter, stdio: true do
  let(:listener) { described_class.new(reps:) }

  let(:reps) do
    Nanoc::Core::ItemRepRepo.new
  end

  let(:item) { Nanoc::Core::Item.new('item content', {}, '/donkey.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :latex) }

  it 'records snapshot_created' do
    listener.start_safely

    expect { Nanoc::Core::NotificationCenter.post(:snapshot_created, rep, :last).sync }
      .to output(%r{Snapshot last created for /donkey.md \(rep name :latex\)}).to_stdout
  end

  it 'prints with timestamp' do
    listener.start_safely

    expect { Nanoc::Core::NotificationCenter.post(:snapshot_created, rep, :last).sync }
      .to output(%r{^\*\*\* \d{2}:\d{2}:\d{2}\.\d{3} .*Snapshot last created for /donkey.md \(rep name :latex\)}).to_stdout
  end

  it 'records cached_content_used' do
    listener.start_safely

    expect { Nanoc::Core::NotificationCenter.post(:cached_content_used, rep).sync }
      .to output(%r{Used cached compiled content for /donkey.md \(rep name :latex\) instead of recompiling}).to_stdout
  end

  it 'records stage_started' do
    listener.start_safely

    expect { Nanoc::Core::NotificationCenter.post(:stage_started, 'Moo').sync }
      .to output(/Stage started: Moo/).to_stdout
  end

  it 'records stage_ended' do
    listener.start_safely

    expect { Nanoc::Core::NotificationCenter.post(:stage_ended, 'Moo').sync }
      .to output(/Stage ended: Moo/).to_stdout
  end

  it 'records stage_aborted' do
    listener.start_safely

    expect { Nanoc::Core::NotificationCenter.post(:stage_aborted, 'Moo').sync }
      .to output(/Stage aborted: Moo/).to_stdout
  end
end
