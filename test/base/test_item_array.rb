# encoding: utf-8

class Nanoc::ItemArrayTest < Nanoc::TestCase

  def setup
    super

    @one = Nanoc::Item.new('Item One', {}, '/one/')
    @two = Nanoc::Item.new('Item Two', {}, '/two/')

    @items = Nanoc::ItemArray.new
    @items << @one
    @items << @two
  end

  def test_change_item_identifier
    assert_equal @one, @items['/one/']
    assert_nil @items['/foo/']

    @one.identifier = '/foo/'

    assert_nil @items['/one/']
    assert_equal @one, @items['/foo/']
  end

  def test_enumerable
    assert_equal @one, @items.find { |i| i.identifier == '/one/' }
  end

  def test_brackets_and_slice_and_at_with_index
    assert_equal @one, @items[0]
    assert_equal @one, @items.slice(0)
    assert_equal @one, @items.at(0)

    assert_equal @two, @items[1]
    assert_equal @two, @items.slice(1)
    assert_equal @two, @items.at(1)

    assert_nil @items[2]
    assert_nil @items.slice(2)
    assert_nil @items.at(2)

    assert_equal @two, @items[-1]
    assert_equal @two, @items.slice(-1)
    assert_equal @two, @items.at(-1)
  end

  def test_brackets_and_slice_with_range
    assert_equal [ @one, @two ], @items[0..1]
    assert_equal [ @one, @two ], @items[0, 2]

    assert_equal [ @one, @two ], @items.slice(0..1)
    assert_equal [ @one, @two ], @items.slice(0, 2)
  end

  def test_brackets_and_slice_and_at_with_identifier
    assert_equal @one, @items['/one/']
    assert_equal @one, @items.slice('/one/')
    assert_equal @one, @items.at('/one/')

    assert_equal @two, @items['/two/']
    assert_equal @two, @items.slice('/two/')
    assert_equal @two, @items.at('/two/')

    assert_nil @items['/max-payne/']
    assert_nil @items.slice('/max-payne/')
    assert_nil @items.at('/max-payne/')
  end

  def test_brackets_and_slice_and_at_with_malformed_identifier
    assert_nil @items['one/']
    assert_nil @items.slice('one/')
    assert_nil @items.at('one/')

    assert_nil @items['/one']
    assert_nil @items.slice('/one')
    assert_nil @items.at('/one')

    assert_nil @items['one']
    assert_nil @items.slice('one')
    assert_nil @items.at('one')

    assert_nil @items['//one/']
    assert_nil @items.slice('//one/')
    assert_nil @items.at('//one/')
  end

  def test_brackets_and_slice_and_at_frozen
    @items.freeze

    assert_equal @one, @items['/one/']
    assert_equal @one, @items.slice('/one/')
    assert_equal @one, @items.at('/one/')

    assert_nil @items['/tenthousand/']
    assert_nil @items.slice('/tenthousand/')
    assert_nil @items.at('/tenthousand/')
  end

  def test_less_than_less_than
    assert_nil @items[2]
    assert_nil @items['/foo/']

    foo = Nanoc::Item.new('Item Foo', {}, '/foo/')
    @items << foo

    assert_equal foo, @items[2]
    assert_equal foo, @items['/foo/']
  end

  def test_assign
    assert_raises(TypeError) do
      @items['/blah/'] = Nanoc::Item.new('Item blah', {}, '/blah/')
    end

    new_item =  Nanoc::Item.new('New Item One', {}, '/one-new/')
    @items[0] = new_item

    assert_equal new_item, @items[0]
    assert_equal new_item, @items['/one-new/']
    assert_nil @items['/one/']
  end

  def test_assign_frozen
    @items.freeze

    new_item = Nanoc::Item.new('New Item One', {}, '/one-new/')

    assert_raises_frozen_error do
      @items[0] = new_item
    end
  end

  def test_clear
    @items.clear

    assert_nil @items[0]
    assert_nil @items[1]
    assert_nil @items[2]

    assert_nil @items['/one/']
    assert_nil @items['/two/']
  end

  def test_collect_bang
    @items.collect! do |i|
      Nanoc::Item.new("New #{i.raw_content}", {}, "/new#{i.identifier}")
    end

    assert_nil @items['/one/']
    assert_nil @items['/two/']

    assert_equal "New Item One", @items[0].raw_content
    assert_equal "New Item One", @items['/new/one/'].raw_content

    assert_equal "New Item Two", @items[1].raw_content
    assert_equal "New Item Two", @items['/new/two/'].raw_content
  end

  def test_collect_bang_frozen
    @items.freeze

    assert_raises_frozen_error do
      @items.collect! do |i|
        Nanoc::Item.new("New #{i.raw_content}", {}, "/new#{i.identifier}")
      end
    end
  end

  def test_concat
    new_item = Nanoc::Item.new('New item', {}, '/new/')
    @items.concat([ new_item ])

    assert_equal new_item, @items[2]
    assert_equal new_item, @items['/new/']
  end

  def test_delete
    assert_equal @two, @items[1]
    assert_equal @two, @items['/two/']

    @items.delete(@two)

    assert_nil @items[1]
    assert_nil @items['/two/']
  end

  def test_delete_at
    assert_equal @two, @items[1]
    assert_equal @two, @items['/two/']

    @items.delete_at(1)

    assert_nil @items[1]
    assert_nil @items['/two/']
  end

  def test_delete_if
    assert_equal @two, @items[1]
    assert_equal @two, @items['/two/']

    @items.delete_if { |i| i.identifier == '/two/' }

    assert_nil @items[1]
    assert_nil @items['/two/']
  end

  def test_fill_all
    @items.fill { |i| Nanoc::Item.new("Item #{i}", {}, "/new/#{i}/") }

    assert_nil @items['/one/']
    assert_nil @items['/two/']

    assert_equal "Item 0", @items[0].raw_content
    assert_equal "Item 0", @items['/new/0/'].raw_content
    assert_equal "Item 1", @items[1].raw_content
    assert_equal "Item 1", @items['/new/1/'].raw_content
  end

  def test_fill_range
    @items.fill(1..-1) { |i| Nanoc::Item.new("Item #{i}", {}, "/new/#{i}/") }

    assert_equal @one, @items['/one/']
    assert_nil @items['/two/']

    assert_equal @one, @items[0]
    assert_equal @one, @items['/one/']
    assert_equal "Item 1", @items[1].raw_content
    assert_equal "Item 1", @items['/new/1/'].raw_content
  end

  if Array.new.respond_to?(:keep_if)
    def test_keep_if
      assert_equal @two, @items[1]
      assert_equal @two, @items['/two/']

      @items.keep_if { |i| i.identifier == '/one/' }

      assert_equal @one, @items[0]
      assert_equal @one, @items['/one/']
      assert_nil @items[1]
      assert_nil @items['/two/']
    end
  end

  def test_pop
    @items.pop

    assert_equal @one, @items[0]
    assert_equal @one, @items['/one/']
    assert_nil @items[1]
    assert_nil @items['/two/']
  end

  def test_push
    pushy = Nanoc::Item.new("Pushy", {}, '/pushy/')
    @items.push(pushy)

    assert_equal @one, @items[0]
    assert_equal @one, @items['/one/']
    assert_equal @two, @items[1]
    assert_equal @two, @items['/two/']
    assert_equal pushy, @items[2]
    assert_equal pushy, @items['/pushy/']
  end

  def test_reject_bang
    assert_equal @two, @items[1]
    assert_equal @two, @items['/two/']

    @items.reject! { |i| i.identifier == '/two/' }

    assert_nil @items[1]
    assert_nil @items['/two/']
  end

  def test_replace
    max  = Nanoc::Item.new("Max", {}, '/max/')
    mona = Nanoc::Item.new('Mona', {}, '/mona/')

    @items.replace([ max, mona ])

    assert_nil @items['/one/']
    assert_nil @items['/two/']

    assert_equal max, @items[0]
    assert_equal max, @items['/max/']
    assert_equal mona, @items[1]
    assert_equal mona, @items['/mona/']
  end

  if Array.new.respond_to?(:select!)
    def test_select_bang
      assert_equal @two, @items[1]
      assert_equal @two, @items['/two/']

      @items.select! { |i| i.identifier == '/two/' }

      assert_nil @items[1]
      assert_nil @items['/one/']
    end
  end

  def test_shift
    @items.shift

    assert_equal @two, @items[0]
    assert_equal @two, @items['/two/']
    assert_nil @items['/one/']
    assert_nil @items[1]
  end

  def test_slice_bang
    @items.slice!(1)

    assert_equal @one, @items[0]
    assert_equal @one, @items['/one/']
    assert_nil @items[1]
    assert_nil @items['/two/']
  end

  def test_unshift
    unshifty = Nanoc::Item.new("Unshifty", {}, '/unshifty/')
    @items.unshift(unshifty)

    assert_equal unshifty, @items[0]
    assert_equal unshifty, @items['/unshifty/']
    assert_equal @one, @items[1]
    assert_equal @one, @items['/one/']
    assert_equal @two, @items[2]
    assert_equal @two, @items['/two/']
  end

end
