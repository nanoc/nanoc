# frozen_string_literal: true

describe Nanoc::CLI::CompileListeners::DiffGenerator do
  describe '.enable_for?' do
    subject { described_class.enable_for?(command_runner, site) }

    let(:options) { {} }
    let(:config_hash) { {} }

    let(:arguments) { double(:arguments) }
    let(:command) { double(:command) }

    let(:site) do
      Nanoc::Core::Site.new(
        config:,
        code_snippets:,
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )
    end

    let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd, hash: config_hash).with_defaults }
    let(:items) { Nanoc::Core::ItemCollection.new(config, []) }
    let(:layouts) { Nanoc::Core::LayoutCollection.new(config, []) }
    let(:code_snippets) { [] }

    let(:command_runner) do
      Nanoc::CLI::Commands::Compile.new(options, arguments, command)
    end

    context 'default' do
      it { is_expected.not_to be }
    end

    context 'enabled in config' do
      let(:config_hash) { { enable_output_diff: true } }

      it { is_expected.to be }
    end

    context 'enabled on command line' do
      let(:options) { { diff: true } }

      it { is_expected.to be }
    end
  end

  describe Nanoc::CLI::CompileListeners::DiffGenerator::Differ do
    subject { differ.call }

    let(:differ) { described_class.new('content/foo.md', str_a, str_b) }

    let(:str_a) do
      %w[a b c d e f g h i j k l m n o p q r s].join("\n")
    end

    let(:str_b) do
      # remove c, d
      # add !!!
      %w[a b e f g h i j k l m !!! n o p q r s].join("\n")
    end

    it 'generates the proper diff' do
      expect(subject).to eq(<<~EOS)
        --- content/foo.md
        +++ content/foo.md
        @@ -1,7 +1,5 @@
         a
         b
        -c
        -d
         e
         f
         g
        @@ -11,6 +9,7 @@
         k
         l
         m
        +!!!
         n
         o
         p
      EOS
    end

    context 'when hunks are overlapping' do
      let(:str_a) do
        <<~EOS
          A
          B
          MOVED
          D
          E
          F
          DELETED
        EOS
      end

      let(:str_b) do
        <<~EOS
          A
          B
          D
          E
          F
          MOVED
        EOS
      end

      it 'correctly merges hunks' do
        expect(subject).to eq(<<~EOS)
          --- content/foo.md
          +++ content/foo.md
          @@ -1,8 +1,7 @@
           A
           B
          -MOVED
           D
           E
           F
          -DELETED
          +MOVED
        EOS
      end
    end
  end
end
