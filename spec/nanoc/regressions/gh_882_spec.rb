describe 'GH-882', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'I am foo!')
    File.write('content/bar.md', 'I am bar!')

    File.write('Rules', <<EOS)
  compile '/**/*' do
    write item.identifier.without_ext + '.html'
  end

  postprocess do
    modified_reps = items.flat_map(&:modified)
    modified_reps.each do |rep|
      puts "Modified: \#{rep.item.identifier} - \#{rep.name}"
    end
  end
EOS
  end

  example do
    Nanoc::CLI.run(%w[compile])

    File.write('content/bar.md', 'I am bar! Modified!')
    expect { Nanoc::CLI.run(%w[compile]) }.to output(%r{^Modified: /bar.md - default$}).to_stdout

    File.write('content/bar.md', 'I am bar! Modified again!')
    expect { Nanoc::CLI.run(%w[compile]) }.not_to output(%r{^Modified: /foo.md - default$}).to_stdout
  end
end
