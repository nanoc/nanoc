require 'test/helper'

describe 'Nanoc::Template' do

  before { global_setup    }
  after  { global_teardown }

  before do
    @template = Nanoc::Template.new('content', { 'foo' => 'bar' }, 'sample')
    @template.site = stub('site', :data_source => mock('data_source'))
  end

  it 'should have clean attributes' do
    @template.page_attributes.keys[0].should == :foo
  end

  it 'should delegate save to data source' do
    @template.site.data_source.expects(:save_template).with(@template)
    @template.site.data_source.expects(:loading).yields

    should.not.raise do
      @template.save
    end
  end

  it 'should delegate move_to to data source' do
    @template.site.data_source.expects(:move_template).with(@template, '/new/path/')
    @template.site.data_source.expects(:loading).yields

    should.not.raise do
      @template.move_to('/new/path/')
    end
  end

  it 'should delegate delete to data source' do
    @template.site.data_source.expects(:delete_template).with(@template)
    @template.site.data_source.expects(:loading).yields

    should.not.raise do
      @template.delete
    end
  end

end
