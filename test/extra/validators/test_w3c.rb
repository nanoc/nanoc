# encoding: utf-8

require 'test/helper'

class Nanoc3::Extra::Validators::W3CTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_simple
    if_have 'w3c_validators' do
      # Create some sample files
      %w{ foo bar baz }.each do |filename|
        %w{ xxx yyy }.each do |extension|
          File.open("#{filename}.#{extension}", 'w') { |io| io.write("hello") }
        end
      end

      # Create validator
      w3c = Nanoc3::Extra::Validators::W3C.new('.', [ :xxx ])

      # Configure expectations
      validator_result = mock
      validator_result.expects(:errors).times(3)
      validator = mock
      validator.expects(:validate_file).times(3).returns(validator_result)
      w3c.expects(:types_to_extensions).with([ :xxx ]).returns([ 'xxx' ])
      w3c.expects(:validator_for).with('xxx').times(3).returns(validator)
      w3c.expects(:validation_started).times(3)
      w3c.expects(:validation_ended).times(3)

      # Run
      w3c.run
    end
  end

  def test_with_unknown_types
    if_have 'w3c_validators' do
      # Create validator
      w3c = Nanoc3::Extra::Validators::W3C.new('.', [ :foo ])

      # Test
      exception = assert_raises RuntimeError do
        w3c.run
      end
      assert_equal 'unknown type: foo', exception.message
    end
  end

end
