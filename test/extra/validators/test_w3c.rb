# encoding: utf-8

class Nanoc::Extra::Validators::W3CTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_simple
    if_have 'w3c_validators' do
      with_site do |site|
        # Create some sample files
        %w{ foo bar baz }.each do |filename|
          %w{ xxx yyy }.each do |extension|
            File.open("output/#{filename}.#{extension}", 'w') { |io| io.write("hello") }
          end
        end

        # Create validator
        w3c = Nanoc::Extra::Validators::W3C.new('.', [ :html ])

        # Run
        w3c.run
      end
    end
  end

  def test_with_unknown_types
    if_have 'w3c_validators' do
      with_site do |site|
        # Create validator
        w3c = Nanoc::Extra::Validators::W3C.new('.', [ :foo ])

        # Test
        exception = assert_raises Nanoc::Errors::GenericTrivial do
          w3c.run
        end
        assert_equal 'unknown type(s) specified: foo', exception.message
      end
    end
  end

end
