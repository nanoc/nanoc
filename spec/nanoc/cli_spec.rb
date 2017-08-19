# frozen_string_literal: true

describe Nanoc::CLI do
  let(:all_commands) do
    ObjectSpace.each_object(Cri::Command)
  end

  let(:exceptions) do
    # FIXME: Get rid of these exceptions by Nanoc 5.0
    [
      ['deploy', ['C']],
      ['help', ['v']],
      ['check', ['d']],
    ]
  end

  def ancestors_of_command(command)
    if command.is_a?(Cri::Command)
      [command] + ancestors_of_command(command.supercommand)
    else
      []
    end
  end

  def short_options_for_command(command)
    ancestors = ancestors_of_command(command)
    ancestors.flat_map { |a| a.option_definitions.to_a.map { |od| od[:short] } }.compact
  end

  it 'has no commands that have conflicting options' do
    all_commands.each do |command|
      short_options = short_options_for_command(command)

      duplicate_options = short_options.select { |o| short_options.count(o) > 1 }.uniq

      next if exceptions.include?([command.name, duplicate_options])

      expect(duplicate_options).to(
        be_empty,
        "The #{command.name} command’s option shorthands #{duplicate_options.uniq} are used by multiple options",
      )
    end
  end
end
