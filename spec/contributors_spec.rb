# frozen_string_literal: true

describe 'list of contributors in README', chdir: false do
  let(:contributors_in_readme) do
    File.readlines('README.md').last.chomp("\n").split(', ')
  end

  let(:contributors_in_release_notes) do
    File.read('NEWS.md').scan(/\[[^\]]+\]$/).map { |s| s[1..-2].split(', ') }.flatten
  end

  it 'should include everyone mentioned in NEWS.md' do
    diff = (contributors_in_release_notes - contributors_in_readme).uniq.sort
    expect(diff).to be_empty, "some contributors are missing from the README: #{diff.join(', ')}"
  end

  it 'should be sorted' do
    expect(contributors_in_readme).to be_humanly_sorted
  end
end
