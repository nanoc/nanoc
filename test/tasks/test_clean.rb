# encoding: utf-8

require 'test/helper'

class Nanoc3::Tasks::CleanTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_simple
    if_have 'w3c_validators' do
      # Stub items
      items = [ mock, mock ]
      reps  = [ [ mock, mock ], [ mock, mock ] ]
      items[0].expects(:reps).returns(reps[0])
      items[1].expects(:reps).returns(reps[1])

      # Create sample files
      [ 0, 1 ].each do |item_id|
        [ 0, 1 ].each do |rep_id|
          filename = "item-#{item_id}-rep-#{rep_id}.txt"
          reps[item_id][rep_id].expects(:raw_path).returns(filename)
          File.open(filename, 'w') { |io| io.write('hello') }
          assert File.file?(filename)
        end
      end

      # Stub site
      site = mock
      site.expects(:load_data)
      site.expects(:items).returns(items)

      # Create clean task
      clean = ::Nanoc3::Tasks::Clean.new(site)

      # Run
      clean.run

      # Check
      [ 0, 1 ].each do |item_id|
        [ 0, 1 ].each do |rep_id|
          filename = "item-#{item_id}-rep-#{rep_id}.txt"
          assert !File.file?(filename)
        end
      end
    end
  end

end
