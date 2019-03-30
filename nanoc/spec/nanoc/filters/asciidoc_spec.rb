# frozen_string_literal: true

describe Nanoc::Filters::AsciiDoc do
  subject { described_class.new }

  before do
    skip_unless_have_command 'asciidoc'
  end

  example do
    expect(subject.setup_and_run('== Blah blah'))
      .to match(%r{<h2 id="_blah_blah">Blah blah</h2>})
  end
end
