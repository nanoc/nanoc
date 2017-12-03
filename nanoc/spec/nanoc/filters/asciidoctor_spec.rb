# frozen_string_literal: true

describe Nanoc::Filters::Asciidoctor do
  subject { filter.setup_and_run(input, params) }

  let(:filter) { described_class.new }

  let(:input) { '== Blah blah' }
  let(:params) { {} }

  it { is_expected.to match(%r{<h2 id="_blah_blah">Blah blah</h2>}) }
end
