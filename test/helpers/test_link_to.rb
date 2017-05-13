# frozen_string_literal: true

require 'helper'

class Nanoc::Helpers::LinkToTest < Nanoc::TestCase
  include Nanoc::Helpers::LinkTo

  def test_examples_link_to
    # Parse
    YARD.parse(LIB_DIR + '/nanoc/helpers/link_to.rb')

    # Mock
    @items = [
      Nanoc::ItemRepView.new(mock, {}),
      Nanoc::ItemRepView.new(mock, {}),
      Nanoc::ItemRepView.new(mock, {}),
    ]
    @items[0].stubs(:identifier).returns('/about/')
    @items[0].stubs(:path).returns('/about.html')
    @items[1].stubs(:identifier).returns('/software/')
    @items[1].stubs(:path).returns('/software.html')
    @items[2].stubs(:identifier).returns('/software/nanoc/')
    @items[2].stubs(:path).returns('/software/nanoc.html')
    about_rep_vcard = Nanoc::ItemRepView.new(mock, {})
    about_rep_vcard.stubs(:path).returns('/about.vcf')
    @items[0].stubs(:rep).with(:vcard).returns(about_rep_vcard)

    # Run
    assert_examples_correct 'Nanoc::Helpers::LinkTo#link_to'
  end

  def test_examples_link_to_unless_current
    # Parse
    YARD.parse(LIB_DIR + '/nanoc/helpers/link_to.rb')

    # Mock
    @item_rep = mock
    @item_rep.stubs(:path).returns('/about/')
    @item = mock
    @item.stubs(:path).returns(@item_rep.path)

    # Run
    assert_examples_correct 'Nanoc::Helpers::LinkTo#link_to_unless_current'
  end

  def test_examples_relative_path_to
    # Parse
    YARD.parse(LIB_DIR + '/nanoc/helpers/link_to.rb')

    # Mock
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/bar/')

    # Run
    assert_examples_correct 'Nanoc::Helpers::LinkTo#relative_path_to'
  end
end
