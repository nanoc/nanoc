# frozen_string_literal: true

describe 'GH-1554', site: true, stdio: true do
  # rubocop:disable RSpec/ExampleLength
  example do
    FileUtils.mkdir_p('content')
    FileUtils.mkdir_p('content/parts')

    File.write('content/main.erb', 'Stuff')
    File.write('content/parts/a.txt', "---\ndraft: false\n---\nPart A")
    File.write('content/parts/b.txt', "---\ndraft: false\n---\nPart B")

    File.write('Rules', <<~CONTENT)
      preprocess do
        @items.delete_if { |i| i[:draft] }
      end

      compile '/*.erb' do
        filter :erb
        write ext: 'txt'
      end

      compile '/**/*.txt' do
        write ext: 'txt'
      end
    CONTENT

    File.write('content/main.erb', '<%= @items.find_all("/parts/*").map(&:compiled_content).sort.join("\n") %>')

    Nanoc::CLI.run([])
    expect(File.file?('output/main.txt')).to be(true)
    expect(File.read('output/main.txt')).to eq("Part A\nPart B")

    File.write('content/parts/b.txt', "---\ndraft: true\n---\nPart B")
    Nanoc::CLI.run([])
    expect(File.file?('output/main.txt')).to be(true)
    expect(File.read('output/main.txt')).to eq('Part A')
  end
  # rubocop:enable RSpec/ExampleLength
end
