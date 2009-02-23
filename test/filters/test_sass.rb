require 'test/helper'

class Nanoc::Filters::SassTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'sass' do
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

  def test_filter_error
    if_have 'sass' do
      # Mock object rep
      obj_rep = MiniTest::Mock.new
      obj_rep.expect(:attribute_named, {}, [ :sass_options ])

      # Create filter
      filter = ::Nanoc::Filters::Sass.new({ :_obj_rep => obj_rep })

      # Run filter
      raised = false
      begin
        filter.run('$*#&!@($')
      rescue Sass::SyntaxError => e
        assert_match '?', e.backtrace[0]
        raised = true
      end
      assert raised
    end
  end

end
