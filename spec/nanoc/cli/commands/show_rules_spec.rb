# frozen_string_literal: true

describe Nanoc::CLI::Commands::ShowRules, stdio: true do
  describe '#run' do
    subject { runner.run }

    let(:runner) do
      described_class.new(options, arguments, command).tap do |runner|
        runner.site = site
      end
    end

    let(:options) { {} }

    let(:arguments) { [] }

    let(:command) { double(:command) }

    let(:site) do
      double(
        :site,
        items: items,
        layouts: layouts,
        compiler: compiler,
      )
    end

    let(:items) do
      Nanoc::Int::IdentifiableCollection.new(
        config,
        [
          Nanoc::Int::Item.new('About Me', {}, '/about.md'),
          Nanoc::Int::Item.new('About My Dog', {}, '/dog.md'),
          Nanoc::Int::Item.new('Raw Data', {}, '/other.dat'),
        ],
      )
    end

    let(:reps) do
      Nanoc::Int::ItemRepRepo.new.tap do |reps|
        reps << Nanoc::Int::ItemRep.new(items['/about.md'], :default)
        reps << Nanoc::Int::ItemRep.new(items['/about.md'], :text)
        reps << Nanoc::Int::ItemRep.new(items['/dog.md'], :default)
        reps << Nanoc::Int::ItemRep.new(items['/dog.md'], :text)
        reps << Nanoc::Int::ItemRep.new(items['/other.dat'], :default)
      end
    end

    let(:layouts) do
      Nanoc::Int::IdentifiableCollection.new(
        config,
        [
          Nanoc::Int::Layout.new('Default', {}, '/default.erb'),
          Nanoc::Int::Layout.new('Article', {}, '/article.haml'),
          Nanoc::Int::Layout.new('Other', {}, '/other.xyzzy'),
        ],
      )
    end

    let(:config) { Nanoc::Int::Configuration.new }

    let(:action_provider) { double(:action_provider, rules_collection: rules_collection) }
    let(:compiler) { double(:compiler, action_provider: action_provider, reps: reps) }

    let(:rules_collection) do
      Nanoc::RuleDSL::RulesCollection.new.tap do |rc|
        rc.add_item_compilation_rule(
          Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/dog.*'), :default, proc {}),
        )
        rc.add_item_compilation_rule(
          Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/*.md'), :default, proc {}),
        )
        rc.add_item_compilation_rule(
          Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/**/*'), :text, proc {}),
        )

        rc.layout_filter_mapping[Nanoc::Int::Pattern.from('/*.haml')] = [:haml, {}]
        rc.layout_filter_mapping[Nanoc::Int::Pattern.from('/*.erb')] = [:erb, {}]
      end
    end

    let(:expected_out) do
      <<-EOS
        \e[1m\e[33mItem /about.md\e[0m:
          Rep default: /*.md
          Rep text: /**/*

        \e[1m\e[33mItem /dog.md\e[0m:
          Rep default: /dog.*
          Rep text: /**/*

        \e[1m\e[33mItem /other.dat\e[0m:
          Rep default: (none)

        \e[1m\e[33mLayout /article.haml\e[0m:
          /*.haml

        \e[1m\e[33mLayout /default.erb\e[0m:
          /*.erb

        \e[1m\e[33mLayout /other.xyzzy\e[0m:
          (none)

      EOS
        .gsub(/^ {8}/, '')
    end

    before do
      expect(compiler).to receive(:build_reps).once
    end

    it 'writes item and layout rules to stdout' do
      expect { subject }.to output(expected_out).to_stdout
    end

    it 'writes status informaion to stderr' do
      expect { subject }.to output("Loading site… done\n").to_stderr
    end
  end
end
