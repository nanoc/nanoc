# encoding: utf-8

class Nanoc::Extra::Checking::CheckTest < Nanoc::TestCase

  def test_output_filenames
    in_site do
      check = Nanoc::Extra::Checking::Check.new(site_here)
      assert check.output_filenames.empty?
      File.open('output/foo.html', 'w') { |io| io.write 'hello' }
      assert_equal [ 'output/foo.html' ], check.output_filenames
    end
  end

end
