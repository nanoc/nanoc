describe Nanoc::Filters::Less, site: true, stdio: true do
  before do
    File.write('content/a.less', '@import "b.less";')
    File.write('content/b.less', 'p { color: red; }')

    File.open('Rules', 'w') do |io|
      io.write "compile '/a.less' do\n"
      io.write "  filter :less\n"
      io.write "  write '/a.css'\n"
      io.write "end\n"
      io.write "\n"
      io.write "compile '/b.less' do\n"
      io.write "  filter :less\n"
      io.write "end\n"
    end
  end

  it 'compiles a.less' do
    skip 'flaky test'

    Nanoc::CLI.run(%w(compile))
    expect(Dir['output/*']).to eql(['output/a.css'])
    expect(File.read('output/a.css')).to match(/^p\s*\{\s*color:\s*red;?\s*\}/)
  end

  it 'recompiles a.less if b.less has changed' do
    skip 'flaky test'

    Nanoc::CLI.run(%w(compile))

    File.write('content/b.less', 'p { color: blue; }')

    Nanoc::CLI.run(%w(compile))
    expect(Dir['output/*']).to eql(['output/a.css'])
    expect(File.read('output/a.css')).to match(/^p\s*\{\s*color:\s*blue;?\s*\}/)
  end
end
