# encoding: utf-8

class Nanoc::ItemArrayTest < Nanoc::TestCase

  def setup
    super

    @one = Nanoc::Item.new(
      Nanoc::TextualContent.new('Item One', File.join(Dir.getwd, 'content/one.md')),
      {},
      '/one.md')
    @two = Nanoc::Item.new(
      Nanoc::TextualContent.new('Item Two', File.join(Dir.getwd, 'content/two.css')),
      {},
      '/two.css')

    @items = Nanoc::ItemArray.new
    @items << @one
    @items << @two
  end

  def test_change_item_identifier
    assert_equal @one, @items['/one.md']
    assert_nil @items['/foo.txt']

    @one.identifier = '/foo.txt'

    assert_nil @items['/one.md']
    assert_equal @one, @items['/foo.txt']
  end

  def test_enumerable
    assert_equal @one, @items.find { |i| i.identifier == '/one.md' }
  end

  def test_glob
    assert_equal [],                       @items.glob('/three.*')
    assert_equal [ @items[0] ],            @items.glob('/one.*')
    assert_equal [ @items[1] ],            @items.glob('/two.*')
    assert_equal [ @items[0], @items[1] ], @items.glob('/*o*.*')
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

  def test_brackets_and_slice_and_at_with_string_identifier
    assert_equal @one, @items['/one.md']
    assert_equal @one, @items.slice('/one.md')
    assert_equal @one, @items.at('/one.md')

    assert_equal @two, @items['/two.css']
    assert_equal @two, @items.slice('/two.css')
    assert_equal @two, @items.at('/two.css')

    assert_nil @items['/max-payne/']
    assert_nil @items.slice('/max-payne/')
    assert_nil @items.at('/max-payne/')
  end

  def test_brackets_and_slice_and_at_with_object_identifier
    identifier_one = Nanoc::Identifier.from_string('/one.md')
    assert_equal @one, @items[identifier_one]
    assert_equal @one, @items.slice(identifier_one)
    assert_equal @one, @items.at(identifier_one)

    identifier_two = Nanoc::Identifier.from_string('/two.css')
    assert_equal @two, @items[identifier_two]
    assert_equal @two, @items.slice(identifier_two)
    assert_equal @two, @items.at(identifier_two)

    identifier_max_payne = Nanoc::Identifier.from_string('/max-payne/')
    assert_nil @items[identifier_max_payne]
    assert_nil @items.slice(identifier_max_payne)
    assert_nil @items.at(identifier_max_payne)
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

    assert_nil @items['//one.md']
    assert_nil @items.slice('//one.md')
    assert_nil @items.at('//one.md')
  end

  def test_brackets_and_slice_and_at_frozen
    @items.freeze

    assert_equal @one, @items['/one.md']
    assert_equal @one, @items.slice('/one.md')
    assert_equal @one, @items.at('/one.md')

    assert_nil @items['/tenthousand/']
    assert_nil @items.slice('/tenthousand/')
    assert_nil @items.at('/tenthousand/')
  end

  def test_less_than_less_than
    assert_nil @items[2]
    assert_nil @items['/foo.txt']

    foo = Nanoc::Item.new('Item Foo', {}, '/foo.txt')
    @items << foo

    assert_equal foo, @items[2]
    assert_equal foo, @items['/foo.txt']
  end

  def test_assign
    assert_raises(TypeError) do
      @items['/blah.sass'] = Nanoc::Item.new('Item blah', {}, '/blah.sass')
    end

    new_item =  Nanoc::Item.new('New Item One', {}, '/one-new.html')
    @items[0] = new_item

    assert_equal new_item, @items[0]
    assert_equal new_item, @items['/one-new.html']
    assert_nil @items['/one.md']
  end

  def test_assign_frozen
    @items.freeze

    new_item = Nanoc::Item.new('New Item One', {}, '/one-new.html')

    assert_raises_frozen_error do
      @items[0] = new_item
    end
  end

  def test_clear
    @items.clear

    assert_nil @items[0]
    assert_nil @items[1]
    assert_nil @items[2]

    assert_nil @items['/one.md']
    assert_nil @items['/two.css']
  end

  def test_collect_bang
    @items.collect! do |i|
      Nanoc::Item.new("New #{i.content.string}", {}, "/new#{i.identifier}")
    end

    assert_nil @items['/one.md']
    assert_nil @items['/two.css']

    assert_equal "New Item One", @items[0].content.string
    assert_equal "New Item One", @items['/new/one.md'].content.string

    assert_equal "New Item Two", @items[1].content.string
    assert_equal "New Item Two", @items['/new/two.css'].content.string
  end

  def test_collect_bang_frozen
    @items.freeze

    assert_raises_frozen_error do
      @items.collect! do |i|
        Nanoc::Item.new("New #{i.content.string}", {}, "/new#{i.identifier}")
      end
    end
  end

  def test_concat
    new_item = Nanoc::Item.new('New item', {}, '/new.md')
    @items.concat([ new_item ])

    assert_equal new_item, @items[2]
    assert_equal new_item, @items['/new.md']
  end

  def test_delete
    assert_equal @two, @items[1]
    assert_equal @two, @items['/two.css']

    @items.delete(@two)

    assert_nil @items[1]
    assert_nil @items['/two.css']
  end

  def test_delete_at
    assert_equal @two, @items[1]
    assert_equal @two, @items['/two.css']

    @items.delete_at(1)

    assert_nil @items[1]
    assert_nil @items['/two.css']
  end

  def test_delete_if
    assert_equal @two, @items[1]
    assert_equal @two, @items['/two.css']

    @items.delete_if { |i| i.identifier == '/two.css' }

    assert_nil @items[1]
    assert_nil @items['/two.css']
  end

  def test_fill_all
    @items.fill { |i| Nanoc::Item.new("Item #{i}", {}, "/new/#{i}.md") }

    assert_nil @items['/one.md']
    assert_nil @items['/two.css']

    assert_equal "Item 0", @items[0].content.string
    assert_equal "Item 0", @items['/new/0.md'].content.string
    assert_equal "Item 1", @items[1].content.string
    assert_equal "Item 1", @items['/new/1.md'].content.string
  end

  def test_fill_range
    @items.fill(1..-1) { |i| Nanoc::Item.new("Item #{i}", {}, "/new/#{i}.md") }

    assert_equal @one, @items['/one.md']
    assert_nil @items['/two.css']

    assert_equal @one, @items[0]
    assert_equal @one, @items['/one.md']
    assert_equal "Item 1", @items[1].content.string
    assert_equal "Item 1", @items['/new/1.md'].content.string
  end

  if Array.new.respond_to?(:keep_if)
    def test_keep_if
      assert_equal @two, @items[1]
      assert_equal @two, @items['/two.css']

      @items.keep_if { |i| i.identifier == '/one.md' }

      assert_equal @one, @items[0]
      assert_equal @one, @items['/one.md']
      assert_nil @items[1]
      assert_nil @items['/two.css']
    end
  end

  def test_pop
    @items.pop

    assert_equal @one, @items[0]
    assert_equal @one, @items['/one.md']
    assert_nil @items[1]
    assert_nil @items['/two.css']
  end

  def test_push
    pushy = Nanoc::Item.new("Pushy", {}, '/pushy.md')
    @items.push(pushy)

    assert_equal @one, @items[0]
    assert_equal @one, @items['/one.md']
    assert_equal @two, @items[1]
    assert_equal @two, @items['/two.css']
    assert_equal pushy, @items[2]
    assert_equal pushy, @items['/pushy.md']
  end

  def test_reject_bang
    assert_equal @two, @items[1]
    assert_equal @two, @items['/two.css']

    @items.reject! { |i| i.identifier == '/two.css' }

    assert_nil @items[1]
    assert_nil @items['/two.css']
  end

  def test_replace
    max  = Nanoc::Item.new("Max", {}, '/max.md')
    mona = Nanoc::Item.new('Mona', {}, '/mona.md')

    @items.replace([ max, mona ])

    assert_nil @items['/one.md']
    assert_nil @items['/two.css']

    assert_equal max, @items[0]
    assert_equal max, @items['/max.md']
    assert_equal mona, @items[1]
    assert_equal mona, @items['/mona.md']
  end

  if Array.new.respond_to?(:select!)
    def test_select_bang
      assert_equal @two, @items[1]
      assert_equal @two, @items['/two.css']

      @items.select! { |i| i.identifier == '/two.css' }

      assert_nil @items[1]
      assert_nil @items['/one.md']
    end
  end

  def test_shift
    @items.shift

    assert_equal @two, @items[0]
    assert_equal @two, @items['/two.css']
    assert_nil @items['/one.md']
    assert_nil @items[1]
  end

  def test_slice_bang
    @items.slice!(1)

    assert_equal @one, @items[0]
    assert_equal @one, @items['/one.md']
    assert_nil @items[1]
    assert_nil @items['/two.css']
  end

  def test_unshift
    unshifty = Nanoc::Item.new("Unshifty", {}, '/unshifty.md')
    @items.unshift(unshifty)

    assert_equal unshifty, @items[0]
    assert_equal unshifty, @items['/unshifty.md']
    assert_equal @one, @items[1]
    assert_equal @one, @items['/one.md']
    assert_equal @two, @items[2]
    assert_equal @two, @items['/two.css']
  end

end
