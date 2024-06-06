# frozen_string_literal: true

describe Nanoc::OrigCLI::Commands::ShowRules, site: true, stdio: true do
  describe '#run' do
    subject { runner.run }

    let(:runner) do
      described_class.new(options, arguments, command)
    end

    let(:options) { {} }

    let(:arguments) { [] }

    let(:command) { double(:command) }

    let(:site) do
      double(
        :site,
        items:,
        layouts:,
        compiler:,
        config:,
      )
    end

    let(:items) do
      Nanoc::Core::ItemCollection.new(
        config,
        [
          Nanoc::Core::Item.new('About Me', {}, '/about.md'),
          Nanoc::Core::Item.new('About My Dog', {}, '/dog.md'),
          Nanoc::Core::Item.new('Raw Data', {}, '/other.dat'),
        ],
      )
    end

    let(:reps) do
      Nanoc::Core::ItemRepRepo.new.tap do |reps|
        reps << Nanoc::Core::ItemRep.new(items.object_with_identifier('/about.md'), :default)
        reps << Nanoc::Core::ItemRep.new(items.object_with_identifier('/about.md'), :text)
        reps << Nanoc::Core::ItemRep.new(items.object_with_identifier('/dog.md'), :default)
        reps << Nanoc::Core::ItemRep.new(items.object_with_identifier('/dog.md'), :text)
        reps << Nanoc::Core::ItemRep.new(items.object_with_identifier('/other.dat'), :default)
      end
    end

    let(:layouts) do
      Nanoc::Core::LayoutCollection.new(
        config,
        [
          Nanoc::Core::Layout.new('Default', {}, '/default.erb'),
          Nanoc::Core::Layout.new('Article', {}, '/article.haml'),
          Nanoc::Core::Layout.new('Other', {}, '/other.xyzzy'),
        ],
      )
    end

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

    let(:action_provider) do
      Class.new(Nanoc::Core::ActionProvider) do
        attr_reader :rules_collection

        def self.for(_context)
          raise NotImplementedError
        end

        def initialize(rules_collection)
          @rules_collection = rules_collection
        end
      end.new(rules_collection)
    end

    let(:compiler) { double(:compiler) }

    let(:rules_collection) do
      Nanoc::RuleDSL::RulesCollection.new.tap do |rc|
        rc.add_item_compilation_rule(
          Nanoc::RuleDSL::CompilationRule.new(Nanoc::Core::Pattern.from('/dog.*'), :default, proc {}),
        )
        rc.add_item_compilation_rule(
          Nanoc::RuleDSL::CompilationRule.new(Nanoc::Core::Pattern.from('/*.md'), :default, proc {}),
        )
        rc.add_item_compilation_rule(
          Nanoc::RuleDSL::CompilationRule.new(Nanoc::Core::Pattern.from('/**/*'), :text, proc {}),
        )

        rc.layout_filter_mapping[Nanoc::Core::Pattern.from('/*.haml')] = [:haml, {}]
        rc.layout_filter_mapping[Nanoc::Core::Pattern.from('/*.erb')] = [:erb, {}]
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

    it 'writes item and layout rules to stdout' do
      expect(runner).to receive(:load_site).and_return(site)
      expect(Nanoc::Core::Compiler).to receive(:new_for).with(site).and_return(compiler)
      expect(compiler).to receive(:run_until_reps_built).and_return(reps:)
      expect(Nanoc::RuleDSL::ActionProvider).to receive(:for).with(site).and_return(action_provider)
      expect { subject }.to output(expected_out).to_stdout
    end

    it 'writes status information to stderr' do
      expect { subject }.to output("Loading site… done\n").to_stderr
    end
  end
end
