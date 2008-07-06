require 'helper'

class Nanoc::VCSTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_named
    assert_nil(Nanoc::VCS.named(:lkasjdlkfjlkasdfkj))

    assert_not_nil(Nanoc::VCS.named(:svn))
    assert_not_nil(Nanoc::VCS.named(:subversion))
  end

  def test_not_implemented
    vcs = Nanoc::VCS.new

    assert_raise(NotImplementedError) { vcs.add('x')       }
    assert_raise(NotImplementedError) { vcs.remove('x')    }
    assert_raise(NotImplementedError) { vcs.move('x', 'y') }
  end

end
