describe Nanoc::Int::Store do
  describe '#tmp_path_for' do
    context 'passing env' do
      subject { described_class.tmp_path_for(env_name: env_name, store_name: 'giraffes') }

      context 'nil given' do
        let(:env_name) { nil }
        it { is_expected.to eql('tmp/giraffes') }
      end

      context 'string given' do
        let(:env_name) { 'staging' }
        it { is_expected.to eql('tmp/staging/giraffes') }
      end
    end

    context 'passing site' do
      subject { described_class.tmp_path_for(site: site, store_name: 'giraffes') }

      let(:site) do
        Nanoc::Int::Site.new(config: config, code_snippets: code_snippets, items: items, layouts: layouts)
      end

      let(:config) { Nanoc::Int::Configuration.new(hash: { 'foo' => 'bar' }) }
      let(:code_snippets) { [] }
      let(:items) { [] }
      let(:layouts) { [] }

      context 'no env specified' do
        it { is_expected.to eql('tmp/giraffes') }
      end

      context 'env specified' do
        let(:config) { Nanoc::Int::Configuration.new(env_name: 'staging', hash: { 'foo' => 'bar' }) }
        it { is_expected.to eql('tmp/staging/giraffes') }
      end
    end
  end
end
