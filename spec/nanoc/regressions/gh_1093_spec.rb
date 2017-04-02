describe 'GH-1093', site: true, stdio: true do
  before do
    File.write('content/index.html', '<%= @items["/z.dat"].reps.all? { |r| File.file?(r.raw_path) } %>')
    File.write('content/z.dat', 'asdf')

    File.write('Rules', <<EOS)
  class TestFilter < Nanoc::Filter
    identifier :gh_1093_test

    def run(content, params = {})
      depend_on(deps)
      content
    end

    private

    def deps
      assigns[:items].find_all('/**/*.dat')
    end
  end

  compile '/**/*.html' do
    filter :gh_1093_test
    filter :erb
    write item.identifier.to_s
  end

  compile '/**/*.dat' do
    write @item.identifier.to_s
  end

  compile '/**/*.dat', rep: :foo do
    write @item.identifier.to_s + '.foo'
  end

  compile '/index.html' do
    filter :erb
    write item.identifier.without_ext + '.txt'
  end

  passthrough '/*.dat'
EOS
  end

  it 'generates dependency on all reps' do
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/index.html')).to eql('true')
  end
end
