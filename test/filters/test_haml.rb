require 'test/helper'

class Nanoc::Filters::HamlTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'haml' do
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

  def test_filter_error
    if_have 'haml' do
      # Mock object rep
      obj_rep = MiniTest::Mock.new
      obj_rep.expect(:attribute_named, {}, [ :haml_options ])

      # Create filter
      filter = ::Nanoc::Filters::Haml.new({ :_obj_rep => obj_rep })

      # Run filter
      raised = false
      begin
        filter.run('%p= this isn\'t really ruby so it\'ll break, muahaha')
      rescue SyntaxError => e
        e.message =~ /(.+?):\d+: /
        assert_match '?', $1
        raised = true
      end
      assert raised
    end
  end

end
