describe Nanoc::CLI::Commands::ShowRules do
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
        compiler: compiler)
    end

    let(:items) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |ic|
        ic << Nanoc::Int::Item.new('About Me', {}, '/about.md').tap do |i|
          i.reps << Nanoc::Int::ItemRep.new(i, :default)
          i.reps << Nanoc::Int::ItemRep.new(i, :text)
        end
        ic << Nanoc::Int::Item.new('About My Dog', {}, '/dog.md').tap do |i|
          i.reps << Nanoc::Int::ItemRep.new(i, :default)
          i.reps << Nanoc::Int::ItemRep.new(i, :text)
        end
        ic << Nanoc::Int::Item.new('Raw Data', {}, '/other.dat').tap do |i|
          i.reps << Nanoc::Int::ItemRep.new(i, :default)
        end
      end
    end

    let(:layouts) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |ic|
        ic << Nanoc::Int::Layout.new('Default', {}, '/default.erb')
        ic << Nanoc::Int::Layout.new('Article', {}, '/article.haml')
        ic << Nanoc::Int::Layout.new('Other', {}, '/other.xyzzy')
      end
    end

    let(:config) { double(:config) }

    let(:compiler) { double(:compiler, rules_collection: rules_collection) }

    let(:rules_collection) do
      Nanoc::Int::RulesCollection.new.tap do |rc|
        rc.add_item_compilation_rule(
          Nanoc::Int::Rule.new(Nanoc::Int::Pattern.from('/dog.*'), :default, proc {}))
        rc.add_item_compilation_rule(
          Nanoc::Int::Rule.new(Nanoc::Int::Pattern.from('/*.md'), :default, proc {}))
        rc.add_item_compilation_rule(
          Nanoc::Int::Rule.new(Nanoc::Int::Pattern.from('/**/*'), :text, proc {}))

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

    it 'outputs item and layout rules' do
      expect { subject }.to output(expected_out).to_stdout
    end
  end
end
