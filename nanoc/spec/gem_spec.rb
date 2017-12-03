# frozen_string_literal: true

describe 'nanoc.gem', chdir: false, stdio: true do
  around do |ex|
    Dir['*.gem'].each { |f| FileUtils.rm(f) }
    ex.run
    Dir['*.gem'].each { |f| FileUtils.rm(f) }
  end

  subject do
    piper = Nanoc::Extra::Piper.new(stdout: $stdout, stderr: $stderr)
    piper.run(%w[gem build nanoc.gemspec], nil)
  end

  it 'builds gem' do
    expect { subject }
      .to change { Dir['*.gem'] }
      .from([])
      .to(include(match(/^nanoc-.*\.gem$/)))
  end
end
