require 'helper'

class Nanoc::Routers::DefaultTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_path_for
    # Create default router
    router = Nanoc::Routers::Default.new(nil)

    # Get page
    page = Nanoc::Page.new(
      'some content',
      { :filename => 'home', :extension => 'htm' },
      '/foo/'
    )

    # Check
    assert_equal('/foo/home.htm', router.path_for(page))
  end

end
