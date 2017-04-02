describe 'GH-937', site: true, stdio: true do
  before do
    File.write('content/style.sass', ".test\n  color: red")

    File.write(
      'nanoc.yaml',
      "sass_style: compact\nenvironments:\n  staging:\n    sass_style: expanded",
    )

    File.write('Rules', <<EOS)
compile '/*.sass' do
  filter :sass, style: @config[:sass_style].to_sym
  write item.identifier.without_ext + '.css'
end
EOS
  end

  it 'does not use cache when switching environments' do
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/style.css')).to eq(".test { color: red; }\n")

    Nanoc::CLI.run(%w[compile --env=staging])
    expect(File.read('output/style.css')).to eq(".test {\n  color: red;\n}\n")
  end
end
