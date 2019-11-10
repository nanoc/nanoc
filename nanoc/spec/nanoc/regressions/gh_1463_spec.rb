# frozen_string_literal: true

describe 'GH-1463', site: true, stdio: true do
  before do
    FileUtils.mkdir_p('content')
    FileUtils.mkdir_p('content/org1')

    File.write('content/org1.erb', <<~CONTENT)
      <ul>
      <% children_of(@item).each do |c| %>
        <li><%= c[:title] %></li>
      <% end %>
      </ul>
    CONTENT

    File.write('content/org1/oink.md', <<~CONTENT)
      ---
      title: Oink
      ---

      here is oink content
    CONTENT

    FileUtils.mkdir_p('lib')
    File.write('lib/default.rb', <<~LIB)
      include Nanoc::Helpers::ChildParent
    LIB

    File.write('Rules', <<~RULES)
      compile '/**/*' do
        filter :erb
        write ext: 'html'
      end
    RULES
  end

  example do
    Nanoc::CLI.run([])
    expect(File.file?('output/org1.html')).to be(true)
    expect(File.read('output/org1.html')).to match(%r{<li>Oink</li>})

    # Remove oink
    FileUtils.rm('content/org1/oink.md')
    Nanoc::CLI.run([])
    expect(File.file?('output/org1.html')).to be(true)
    expect(File.read('output/org1.html')).not_to match(%r{<li>Oink</li>})

    # Re-add oink
    File.write('content/org1/oink.md', <<~CONTENT)
      ---
      title: Oink
      ---

      here is oink content
    CONTENT
    Nanoc::CLI.run([])
    expect(File.file?('output/org1.html')).to be(true)
    expect(File.read('output/org1.html')).to match(%r{<li>Oink</li>})
  end
end
