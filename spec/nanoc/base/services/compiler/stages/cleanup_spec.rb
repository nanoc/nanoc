describe Nanoc::Int::Compiler::Stages::Cleanup do
  let(:stage) { described_class.new(config) }

  let(:config) do
    Nanoc::Int::Configuration.new.with_defaults
  end

  describe '#run' do
    subject { stage.run }

    example do
      FileUtils.mkdir_p('tmp/2f0692fb1a1d')
      FileUtils.mkdir_p('tmp/1a2195bfef6c')
      FileUtils.mkdir_p('tmp/1029d67644815')

      expect { subject }
        .to change { Dir.glob('tmp/*').sort }
        .from(['tmp/1029d67644815', 'tmp/1a2195bfef6c', 'tmp/2f0692fb1a1d'])
        .to(['tmp/1029d67644815'])
    end
  end
end
