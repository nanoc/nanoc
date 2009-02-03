require 'test/helper'

class Nanoc::Filters::HamlTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'haml' do
      assert_nothing_raised do
        # Mock object rep
        obj_rep = MiniTest::Mock.new
        obj_rep.expect(:attribute_named, {}, [ :haml_options ])

        # Create filter
        filter = ::Nanoc::Filters::Haml.new({ :_obj_rep => obj_rep, :question => 'Is this the Payne residence?' })

        # Run filter (no assigns)
        result = filter.run('%html')
        assert_match(/<html>.*<\/html>/, result)

        # Run filter (assigns without @)
        result = filter.run('%p= question')
        assert_equal("<p>Is this the Payne residence?</p>\n", result)

        # Run filter (assigns with @)
        result = filter.run('%p= @question')
        assert_equal("<p>Is this the Payne residence?</p>\n", result)
      end
    end
  end

end
