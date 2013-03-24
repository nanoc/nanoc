# encoding: utf-8

class Nanoc::Extra::Checking::CheckTest < Nanoc::TestCase

  def test_output_filenames
    with_site do |site|
      check = Nanoc::Extra::Checking::Check.new(site)
      assert check.output_filenames.empty?
      File.open('output/foo.html', 'w') { |io| io.write 'hello' }
      assert_equal [ 'output/foo.html' ], check.output_filenames
    end
  end

end
