require 'helper'

class Nanoc::CodeTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestDataSource

    attr_reader :save_called, :was_loaded

    def initialize
      @save_called  = false
      @references   = 0
      @was_loaded   = false
    end

    def loading
      # Load if necessary
      up if @references == 0
      @references += 1

      yield
    ensure
      # Unload if necessary
      @references -= 1
      down if @references == 0
    end

    def up
      @was_loaded = true
    end

    def down
    end

    def save_code(code)
      @save_called = true
    end

  end

  class TestSite

    def data_source
      @data_source ||= TestDataSource.new
    end

  end

  def test_load
    # Initialize
    $complete_insane_parrot = 'meow'

    # Create code and load it
    code = Nanoc::Code.new("$complete_insane_parrot = 'woof'")
    code.load

    # Ensure code is loaded
    assert_equal('woof', $complete_insane_parrot)
  end

  def test_load_with_toplevel_binding
    # Initialize
    @foo = 'meow'

    # Create code and load it
    code = Nanoc::Code.new("@foo = 'woof'")
    code.load

    # Ensure binding is correct
    assert_equal('meow', @foo)
  end

  def test_save
    # Create site
    site = TestSite.new

    # Create code
    code = Nanoc::Code.new("@foo = 'woof'")
    code.site = site

    # Save
    assert(!site.data_source.save_called)
    assert(!site.data_source.was_loaded)
    code.save
    assert(site.data_source.save_called)
    assert(site.data_source.was_loaded)
  end

end
