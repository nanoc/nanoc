describe Nanoc::CLI::Commands::CompileListeners::DiffGenerator do
  describe '.enable_for?' do
    subject { described_class.enable_for?(command_runner) }

    let(:options) { {} }
    let(:config_hash) { {} }

    let(:arguments) { double(:arguments) }
    let(:command) { double(:command) }

    let(:site) do
      Nanoc::Int::Site.new(
        config: config,
        code_snippets: code_snippets,
        data_source: Nanoc::Int::InMemDataSource.new(items, layouts),
      )
    end

    let(:config) { Nanoc::Int::Configuration.new(hash: config_hash).with_defaults }
    let(:items) { [] }
    let(:layouts) { [] }
    let(:code_snippets) { [] }

    let(:command_runner) do
      Nanoc::CLI::Commands::Compile.new(options, arguments, command).tap do |cr|
        cr.site = site
      end
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
end
