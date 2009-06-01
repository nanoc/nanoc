# encoding: utf-8

require 'test/helper'

class Nanoc3::Tasks::Validate::HTMLTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_simple
    if_have 'w3c_validators' do
      # Stub site
      site = mock
      site.expects(:load_data)
      site.expects(:config).returns({ :output_dir => '.' })

      # Create validator
      w3c = Nanoc3::Tasks::Validate::W3C.new(site, nil)

      # Create some sample files
      %w{ foo bar baz qux }.each do |filename|
        %w{ xxx yyy }.each do |extension|
          File.open("#{filename}.#{extension}", 'w') { |io| io.write("hello") }
        end
      end

      # Configure expectations
      validator_result = mock
      validator_result.expects(:errors).times(4)
      validator = mock
      validator.expects(:validate_file).times(4).returns(validator_result)
      w3c.expects(:validator).times(4).returns(validator)
      w3c.expects(:extensions).returns([ 'xxx' ])
      w3c.expects(:validation_started).times(4)
      w3c.expects(:validation_ended).times(4)

      # Run
      w3c.run
    end
  end

end
