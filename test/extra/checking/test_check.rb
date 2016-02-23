class Nanoc::Extra::Checking::CheckTest < Nanoc::TestCase
  def test_output_filenames
    with_site do |site|
      File.open('output/foo.html', 'w') { |io| io.write 'hello' }
      check = Nanoc::Extra::Checking::Check.create(site)
      assert_equal ['output/foo.html'], check.output_filenames
    end
  end

  def test_no_output_dir
    with_site do |site|
      site = site.copy_with_config(Nanoc::Int::Configuration.new(output_dir: 'non-existent'))
      assert_raises Nanoc::Extra::Checking::OutputDirNotFoundError do
        Nanoc::Extra::Checking::Check.create(site)
      end
    end
  end
end
