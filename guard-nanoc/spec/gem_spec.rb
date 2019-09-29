# frozen_string_literal: true

describe 'guard-nanoc.gem', chdir: false, stdio: true do
  subject do
    TTY::Command.new.run('gem build guard-nanoc.gemspec')
  end

  around do |ex|
    Dir['*.gem'].each { |f| FileUtils.rm(f) }
    ex.run
    Dir['*.gem'].each { |f| FileUtils.rm(f) }
  end

  it 'builds gem' do
    STDOUT.puts `pwd`
    expect { subject }
      .to change { Dir['*.gem'] }
      .from([])
      .to(include(match(/^guard-nanoc-.*\.gem$/)))
  end
end
