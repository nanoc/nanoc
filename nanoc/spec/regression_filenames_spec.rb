# frozen_string_literal: true

describe 'regression tests', chdir: false do
  let(:regression_test_filenames) do
    Dir['spec/nanoc/regressions/*']
  end

  let(:regression_test_numbers) do
    regression_test_filenames
      .map { |fn| File.readlines(fn).find { |l| l =~ /^describe/ }.match(/GH-(\d+)/)[1] }
  end

  it 'should have the proper filenames' do
    regression_test_filenames.zip(regression_test_numbers) do |fn, num|
      expect(fn).to match(/gh_#{num}[a-z]*_spec/), "#{fn} has the wrong name in its #define block"
    end
  end
end
