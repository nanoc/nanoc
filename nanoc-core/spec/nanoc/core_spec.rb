# frozen_string_literal: true

describe Nanoc::Core do
  it 'has up-to-date version information' do
    current_year = Date.today.year
    expect(described_class.version_information).to match(/–#{current_year} /)
  end
end
