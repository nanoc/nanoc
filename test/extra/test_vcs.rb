# encoding: utf-8

class Nanoc::Extra::VCSTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_named
    assert_nil(Nanoc::Extra::VCS.named(:lkasjdlkfjlkasdfkj))

    refute_nil(Nanoc::Extra::VCS.named(:svn))
    refute_nil(Nanoc::Extra::VCS.named(:subversion))
  end

  def test_not_implemented
    vcs = Nanoc::Extra::VCS.new

    assert_raises(NotImplementedError) { vcs.add('x')       }
    assert_raises(NotImplementedError) { vcs.remove('x')    }
    assert_raises(NotImplementedError) { vcs.move('x', 'y') }
  end

end
