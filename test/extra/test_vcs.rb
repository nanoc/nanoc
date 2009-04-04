require 'test/helper'

class Nanoc::Extra::VCSTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_named
    assert_nil(Nanoc::Extra::VCS.named(:lkasjdlkfjlkasdfkj))

    assert_not_nil(Nanoc::Extra::VCS.named(:svn))
    assert_not_nil(Nanoc::Extra::VCS.named(:subversion))
  end

  def test_not_implemented
    vcs = Nanoc::Extra::VCS.new

    assert_raise(NotImplementedError) { vcs.add('x')       }
    assert_raise(NotImplementedError) { vcs.remove('x')    }
    assert_raise(NotImplementedError) { vcs.move('x', 'y') }
  end

end
