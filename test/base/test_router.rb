require 'helper'

class Nanoc::RouterTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_disk_path_for
    # Create router
    router = Nanoc::Router.new(nil)

    # Make sure an error is raised
    assert_raise(NotImplementedError) do
      router.disk_path_for(nil)
    end
  end

  def test_web_path_for
    # Create router
    router = Nanoc::Router.new(nil)

    # Make sure an error is raised
    assert_raise(NotImplementedError) do
      router.web_path_for(nil)
    end
  end

end
