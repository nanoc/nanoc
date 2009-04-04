require 'test/helper'

class Nanoc::TemplateTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Make sure attributes are cleaned
    template = Nanoc::Template.new('content', { 'foo' => 'bar' }, 'sample')
    assert_equal({ :foo => 'bar' }, template.page_attributes)
  end

  def test_save
    # Create site
    site = mock

    # Create template
    template = Nanoc::Template.new("content", { :attr => 'ibutes'}, 'name')
    template.site = site

    # Create data source
    data_source = mock
    site.stubs(:data_source).returns(data_source)
    data_source.expects(:loading).yields
    data_source.expects(:save_template).with(template)

    # Save
    template.save
  end

  def test_move_to
    # Create site
    site = mock

    # Create template
    template = Nanoc::Template.new("content", { :attr => 'ibutes'}, 'name')
    template.site = site

    # Create data source
    data_source = mock
    site.stubs(:data_source).returns(data_source)
    data_source.expects(:loading).yields
    data_source.expects(:move_template).with(template, 'new_name')

    # Move
    template.move_to('new_name')
  end

  def test_delete
    # Create site
    site = mock

    # Create template
    template = Nanoc::Template.new("content", { :attr => 'ibutes'}, 'name')
    template.site = site

    # Create data source
    data_source = mock
    site.stubs(:data_source).returns(data_source)
    data_source.expects(:loading).yields
    data_source.expects(:delete_template).with(template)

    # Delete
    template.delete
  end

end
