require 'test/helper'

class Nanoc::ExtraCoreExtHashTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_to_split_yaml_builtin_only
    hash = { :layout => 'foo' }
    assert_equal(
      "# Built-in \nlayout: foo\n\n# Custom\n",
      hash.to_split_yaml
    )
  end

  def test_to_split_yaml_custom_only
    hash = { :foo => 'bar' }
    assert_equal(
      "# Built-in\n\n# Custom \nfoo: bar\n",
      hash.to_split_yaml
    )
  end

  def test_to_split_yaml_builtin_and_custom
    hash = { :layout => 'foo', :foo => 'bar' }
    assert_equal(
      "# Built-in \nlayout: foo\n\n# Custom \nfoo: bar\n",
      hash.to_split_yaml
    )
  end

  def test_to_split_yaml_arrays
    hash = { :filters_pre => %w( foo bar baz ), :filters_post => %w( xxx yyy zzz ) }
    assert_match(
      /# Built-in.*(filters_pre: \n- foo\n- bar\n- baz|filters_post: \n- xxx\n- yyy\n- zzz){2}.*\n\n# Custom/x,
      hash.to_split_yaml
    )
  end

end
