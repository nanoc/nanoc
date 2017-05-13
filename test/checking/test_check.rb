# frozen_string_literal: true

require 'helper'

class Nanoc::Checking::CheckTest < Nanoc::TestCase
  def test_output_filenames
    with_site do |site|
      File.open('output/foo.html', 'w') { |io| io.write 'hello' }
      check = Nanoc::Checking::Check.create(site)
      assert_equal ['output/foo.html'], check.output_filenames
    end
  end

  def test_no_output_dir
    with_site do |site|
      site.config[:output_dir] = 'non-existent'
      assert_raises Nanoc::Checking::OutputDirNotFoundError do
        Nanoc::Checking::Check.create(site)
      end
    end
  end
end
