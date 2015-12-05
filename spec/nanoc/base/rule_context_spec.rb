describe(Nanoc::Int::RuleContext) do
  subject(:rule_context) do
    described_class.new(rep: rep, site: site, executor: executor, view_context: view_context)
  end

  let(:item) { Nanoc::Int::Item.new('content', {}, '/foo.md') }
  let(:config) { Nanoc::Int::Configuration.new }
  let(:items) { Nanoc::Int::IdentifiableCollection.new(config) }
  let(:layouts) { Nanoc::Int::IdentifiableCollection.new(config) }

  let(:rep) { double(:rep, item: item) }
  let(:site) { double(:site, items: items, layouts: layouts, config: config) }
  let(:executor) { double(:executor) }
  let(:view_context) { double(:view_context) }

  describe '#initialize' do
    it 'wraps objects in view classes' do
      expect(subject.rep.class).to eql(Nanoc::ItemRepView)
      expect(subject.item.class).to eql(Nanoc::ItemView)
      expect(subject.site.class).to eql(Nanoc::SiteView)
      expect(subject.config.class).to eql(Nanoc::ConfigView)
      expect(subject.layouts.class).to eql(Nanoc::LayoutCollectionView)
      expect(subject.items.class).to eql(Nanoc::ItemCollectionView)
    end

    it 'contains the right objects' do
      expect(rule_context.rep.unwrap).to eql(rep)
      expect(rule_context.item.unwrap).to eql(item)
      expect(rule_context.site.unwrap).to eql(site)
      expect(rule_context.config.unwrap).to eql(config)
      expect(rule_context.layouts.unwrap).to eql(layouts)
      expect(rule_context.items.unwrap).to eql(items)
    end
  end

  describe '#filter' do
    subject { rule_context.filter(filter_name, filter_args) }

    let(:filter_name) { :donkey }
    let(:filter_args) { { color: 'grey' } }

    it 'makes a request to the executor' do
      expect(executor).to receive(:filter).with(rep, filter_name, filter_args)
      subject
    end
  end

  describe '#layout' do
    subject { rule_context.layout(layout_identifier, extra_filter_args) }

    let(:layout_identifier) { '/default.*' }
    let(:extra_filter_args) { { color: 'grey' } }

    it 'makes a request to the executor' do
      expect(executor).to receive(:layout).with(rep, layout_identifier, extra_filter_args)
      subject
    end
  end

  describe '#snapshot' do
    subject { rule_context.snapshot(snapshot_name, path: path) }

    let(:snapshot_name) { :for_snippet }
    let(:path) { '/foo.html' }

    it 'makes a request to the executor' do
      expect(executor).to receive(:snapshot).with(rep, :for_snippet, path: '/foo.html')
      subject
    end
  end

  describe '#write' do
    subject { rule_context.write(path) }

    let(:path) { '/foo.html' }

    it 'makes a request to the executor' do
      expect(executor).to receive(:snapshot).with(rep, :last, path: '/foo.html')
      subject
    end
  end
end
