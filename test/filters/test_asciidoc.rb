# encoding: utf-8

class Nanoc3::Filters::AsciiDocTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter
    if `which asciidoc`.strip.empty?
      skip "could not find asciidoc"
    end

    # Create filter
    filter = ::Nanoc3::Filters::AsciiDoc.new

    # Run filter
    result = filter.run("== Blah blah")
    assert_match %r{<h2 id="_blah_blah">Blah blah</h2>}, result
  end

end
