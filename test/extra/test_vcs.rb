require 'test/helper'

class Nanoc3::Extra::VCSTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_named
    assert_nil(Nanoc3::Extra::VCS.named(:lkasjdlkfjlkasdfkj))

    refute_nil(Nanoc3::Extra::VCS.named(:svn))
    refute_nil(Nanoc3::Extra::VCS.named(:subversion))
  end

  def test_not_implemented
    vcs = Nanoc3::Extra::VCS.new

    assert_raises(NotImplementedError) { vcs.add('x')       }
    assert_raises(NotImplementedError) { vcs.remove('x')    }
    assert_raises(NotImplementedError) { vcs.move('x', 'y') }
  end

end
