# frozen_string_literal: true

describe 'manifest', chdir: false do
  let(:manifest_lines) do
    File.readlines('nanoc.manifest').map(&:chomp).reject(&:empty?)
  end

  let(:gemspec_lines) do
    gemspec = eval(File.read('nanoc.gemspec'), binding, 'nanoc.gemspec')
    gemspec.files
  end

  it 'contains all files in gemspec' do
    missing_from_manifest = gemspec_lines - manifest_lines
    expect(missing_from_manifest).to be_empty
  end

  it 'contains no files not in gemspec' do
    extra_in_manifest = manifest_lines - gemspec_lines
    expect(extra_in_manifest).to be_empty
  end
end
