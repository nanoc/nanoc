# encoding: utf-8

class Nanoc::Filters::AsciiDocTest < Nanoc::TestCase

  def test_filter
    if_have 'systemu' do
      if `which asciidoc`.strip.empty?
        skip "could not find asciidoc"
      end

      # Create filter
      filter = ::Nanoc::Filters::AsciiDoc.new

      # Run filter
      result = filter.setup_and_run("== Blah blah")
      assert_match %r{<h2 id="_blah_blah">Blah blah</h2>}, result
    end
  end

end
