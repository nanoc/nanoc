# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::AsciiDocTest < Nanoc::TestCase
  def test_filter
    skip_unless_have_command 'asciidoc'

    # Create filter
    filter = ::Nanoc::Filters::AsciiDoc.new

    # Run filter
    result = filter.setup_and_run('== Blah blah')
    assert_match %r{<h2 id="_blah_blah">Blah blah</h2>}, result
  end
end
