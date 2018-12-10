# frozen_string_literal: true

describe Nanoc::CLI::Commands::CompileListeners::DebugPrinter, stdio: true do
  let(:listener) { described_class.new(reps: reps) }

  let(:reps) do
    Nanoc::Int::ItemRepRepo.new
  end

  it 'records stage_started' do
    listener.start_safely

    expect { Nanoc::Int::NotificationCenter.post(:stage_started, 'Moo').sync }
      .to output(/Stage started: Moo/).to_stdout
  end

  it 'records stage_ended' do
    listener.start_safely

    expect { Nanoc::Int::NotificationCenter.post(:stage_ended, 'Moo').sync }
      .to output(/Stage ended: Moo/).to_stdout
  end

  it 'records stage_aborted' do
    listener.start_safely

    expect { Nanoc::Int::NotificationCenter.post(:stage_aborted, 'Moo').sync }
      .to output(/Stage aborted: Moo/).to_stdout
  end
end
