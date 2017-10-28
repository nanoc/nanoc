# frozen_string_literal: true

describe 'manifest', chdir: false do
  let(:gem_names) do
    Dir['*.gemspec'].map { |fn| fn.sub(/\.gemspec$/, '') }
  end

  let(:manifest_lines) do
    gem_names.each_with_object({}) do |gem_name, memo|
      raw_lines = File.readlines(gem_name + '.manifest')
      memo[gem_name] = raw_lines.map(&:chomp).reject(&:empty?)
    end
  end

  let(:gemspec_lines) do
    gem_names.each_with_object({}) do |gem_name, memo|
      gemspec_filename = gem_name + '.gemspec'
      gemspec = eval(File.read(gemspec_filename), binding, gemspec_filename)
      memo[gem_name] = gemspec.files
    end
  end

  it 'contains all files in gemspec' do
    gem_names.each do |gem_name|
      missing_from_manifest = gemspec_lines.fetch(gem_name) - manifest_lines.fetch(gem_name)
      expect(missing_from_manifest).to be_empty, "Found files that appear in the gemspec, but not in the manifest: #{missing_from_manifest.join(', ')}"
    end
  end

  it 'contains no files not in gemspec' do
    gem_names.each do |gem_name|
      extra_in_manifest = manifest_lines.fetch(gem_name) - gemspec_lines.fetch(gem_name)
      expect(extra_in_manifest).to be_empty, "Found files that appear in the manifest, but not in the gemspec: #{extra_in_manifest.join(', ')}"
    end
  end
end
