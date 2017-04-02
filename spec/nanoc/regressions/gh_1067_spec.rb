describe 'GH-1067', site: true, stdio: true do
  before do
    File.write('nanoc.yaml', <<EOS)
environments:
  default:
    build: dev
  prod:
    build: prod
EOS

    File.write('content/foo.erb', 'build=<%= @config[:build] %>')

    File.write('Rules', <<EOS)
  compile '/*' do
    filter :erb
    write item.identifier
  end
EOS
  end

  it 'recompiles when env changes' do
    ENV['NANOC_ENV'] = nil
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/foo.erb')).to eql('build=dev')

    ENV['NANOC_ENV'] = nil
    Nanoc::CLI.run(%w[compile -e prod])
    expect(File.read('output/foo.erb')).to eql('build=prod')

    ENV['NANOC_ENV'] = nil
    Nanoc::CLI.run(%w[compile])
    expect(File.read('output/foo.erb')).to eql('build=dev')
  end
end
