require 'helper'

class Nanoc::PluginTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_identifiers
    # Create plugin
    plugin = Nanoc::Plugin.new

    # Update identifier
    plugin.class.class_eval { identifier :foo }

    # Check
    assert_equal(:foo, plugin.class.class_eval { identifier })
    assert_equal([ :foo ], plugin.class.class_eval { identifiers })

    # Update identifier
    plugin.class.class_eval { identifiers :foo, :bar }

    # Check
    assert_equal([ :foo, :bar ], plugin.class.class_eval { identifiers })
  end

  def test_named
    assert_nothing_raised do
      # Find existant filter
      filter = Nanoc::Filter.named(:erb)
      assert(!filter.nil?)

      # Find non-existant filter
      filter = Nanoc::Filter.named(:lksdaffhdlkashlgkskahf)
      assert(filter.nil?)
    end
  end

  def test_find
    assert_nothing_raised do
      # Find existant filter
      filter = Nanoc::Filter.named(:erb)
      assert(!filter.nil?)

      # Find non-existant filter
      filter = Nanoc::Filter.named(:lksdaffhdlkashlgkskahf)
      assert(filter.nil?)
    end
  end

  def test_find_all
    assert_nothing_raised do
      # Get filters
      filters = Nanoc::Plugin.find_all(Nanoc::Filter)

      # Check
      assert(!filters.nil?)
      assert(filters.include?(Nanoc::Filters::ERB))
      assert(!filters.include?(Nanoc::DataSources::Filesystem))
      assert(!filters.include?(Nanoc::Routers::Default))
    end
  end

end
