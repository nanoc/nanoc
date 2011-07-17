# encoding: utf-8

class Nanoc::Filters::AsciiDocTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'systemu' do
      if `which asciidoc`.strip.empty?
        skip "could not find asciidoc"
      end

      # Create filter
      filter = ::Nanoc::Filters::AsciiDoc.new

      # Run filter
      result = filter.run("== Blah blah")
      assert_match %r{<h2 id="_blah_blah">Blah blah</h2>}, result
    end
  end

end
