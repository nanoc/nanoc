# frozen_string_literal: true

describe 'manifest', chdir: false do
  let(:manifest_lines) do
    File.readlines('nanoc-live.manifest').map(&:chomp).reject(&:empty?)
  end

  let(:gemspec_lines) do
    gemspec = eval(File.read('nanoc-live.gemspec'), binding, 'nanoc-live.gemspec')
    gemspec.files
  end

  it 'contains all files in gemspec' do
    missing_from_manifest = gemspec_lines - manifest_lines
    expect(missing_from_manifest).to be_empty, "Found files that appear in the gemspec, but not in the manifest: #{missing_from_manifest.join(', ')}"
  end

  it 'contains no files not in gemspec' do
    extra_in_manifest = manifest_lines - gemspec_lines
    expect(extra_in_manifest).to be_empty, "Found files that appear in the manifest, but not in the gemspec: #{extra_in_manifest.join(', ')}"
  end
end
