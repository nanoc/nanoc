# encoding: utf-8

class Nanoc::Filters::AsciidoctorTest < Nanoc::TestCase

  def test_filter
    if_have 'asciidoctor' do
      # Create filter
      filter = ::Nanoc::Filters::AsciiDoc.new

      # Run filter
      result = filter.setup_and_run("== Blah blah")
      assert_match %r{<h2 id="_blah_blah">Blah blah</h2>}, result
    end
  end

end
