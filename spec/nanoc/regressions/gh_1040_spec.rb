# frozen_string_literal: true

describe 'GH-1040', site: true, stdio: true do
  before do
    File.write('content/foo.txt', 'bar=<%= @items["/bar.*"].compiled_content %>')
    File.write('content/bar.txt', 'foo=<%= @items["/foo.*"].compiled_content %>')

    File.write('layouts/default.erb', '*<%= yield %>*')

    File.write('Rules', <<EOS)
  compile '/*' do
    filter :erb
    layout '/default.*'
    write item.identifier
  end

  layout '/*.erb', :erb
EOS
  end

  it 'errors' do
    expect { Nanoc::CLI.run(%w[compile]) }.to raise_error(Nanoc::Int::Errors::DependencyCycle)
  end
end
