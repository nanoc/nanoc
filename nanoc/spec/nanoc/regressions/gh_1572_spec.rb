# frozen_string_literal: true

describe 'GH-1572', site: true, stdio: true do
  # rubocop:disable RSpec/ExampleLength
  example do
    FileUtils.mkdir_p('content')

    allow_any_instance_of(Nanoc::Core::BinaryCompiledContentCache)
      .to receive(:use_clonefile?)
      .and_return(false)

    File.write('content/repro.jpg', '<data>')
    File.chmod(0o400, 'content/repro.jpg')
    expect(File.stat('content/repro.jpg').mode).to eq(0o100400)

    Nanoc::CLI.run([])
    expect(File.file?('output/repro.jpg')).to be(true)
    expect(File.read('output/repro.jpg')).to eq('<data>')
    expect(File.stat('output/repro.jpg').mode).to eq(0o100400)

    FileUtils.rm_f('output/repro.jpg')
    Nanoc::CLI.run([])
    expect(File.file?('output/repro.jpg')).to be(true)
    expect(File.read('output/repro.jpg')).to eq('<data>')
    expect(File.stat('output/repro.jpg').mode).to eq(0o100400)
  end
  # rubocop:enable RSpec/ExampleLength
end
