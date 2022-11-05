# frozen_string_literal: true

require_relative '../../common/spec/spec_helper_head_core'

require 'nanoc/cli'

require_relative '../../common/spec/spec_helper_foot_core'

Nanoc::CLI.setup

Class.new(Nanoc::Core::DataSource) do
  # fake
  identifier :filesystem

  def items
    Dir['content/*'].map do |filename|
      Nanoc::Core::Item.new(File.read(filename), {}, filename.sub(/^content\//, '/'))
    end
  end

  def layouts
    Dir['layouts/*'].map do |filename|
      Nanoc::Core::Layout.new(File.read(filename), {}, filename.sub(/^layouts\//, '/'))
    end
  end
end

Class.new(Nanoc::Core::ActionProvider) do
  # fake
  identifier :rule_dsl

  def self.for(_site)
    new
  end

  def need_preprocessing?
    true
  end

  def preprocess(site)
    item = site.items.object_matching_glob('/hello.*')

    if item
      item.content = Nanoc::Core::TextualContent.new('Better hello!')
    end
  end

  def postprocess(_site, _reps); end

  def rep_names_for(_item)
    [:default]
  end

  def action_sequence_for(rep)
    Nanoc::Core::ActionSequence.new(
      actions: [
        Nanoc::Core::ProcessingActions::Snapshot.new([:last], [rep.item.identifier.to_s]),
      ],
    )
  end

  def snapshots_defs_for(_rep)
    [Nanoc::Core::SnapshotDef.new(:last, binary: false)]
  end
end
