require 'test/helper'

class Nanoc::Filters::SassTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'sass' do
      assert_nothing_raised do
        # Mock object rep
        obj_rep = MiniTest::Mock.new
        obj_rep.expect(:attribute_named, {}, [ :sass_options ])

        # Get filter
        filter = ::Nanoc::Filters::Sass.new({ :_obj_rep => obj_rep })

        # Run filter
        result = filter.run(".foo #bar\n  color: #f00")
        assert_match(/.foo\s+#bar\s*\{\s*color:\s+#f00;?\s*\}/, result)
      end
    end
  end

end
