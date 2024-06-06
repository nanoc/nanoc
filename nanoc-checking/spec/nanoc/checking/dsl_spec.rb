# frozen_string_literal: true

describe Nanoc::Checking::DSL do
  it 'can read from file' do
    File.write('Checks', "check :foo do\n\nend\ndeploy_check :bar\n")
    enabled_checks = []
    described_class.from_file('Checks', enabled_checks:)

    expect(Nanoc::Checking::Check.named(:foo)).not_to be_nil
    expect(enabled_checks).to eq([:bar])
  end

  it 'can load relative files' do
    File.write('stuff.rb', '$greeting = "hello"')
    File.write('Checks', 'require "./stuff"')
    described_class.from_file('Checks', enabled_checks: [])

    expect($greeting).to eq('hello')
  end

  it 'has an absolute path' do
    File.write('Checks', '$stuff = __FILE__')
    described_class.from_file('Checks', enabled_checks: [])

    pathname = Pathname.new($stuff)
    expect(pathname).to be_absolute
  end
end
