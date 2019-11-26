# frozen_string_literal: true

describe 'nanoc-checking.gem', chdir: false, stdio: true do
  subject do
    TTY::Command.new.run('gem build nanoc-checking.gemspec')
  end

  around do |ex|
    Dir['*.gem'].each { |f| FileUtils.rm(f) }
    ex.run
    Dir['*.gem'].each { |f| FileUtils.rm(f) }
  end

  it 'builds gem' do
    expect { subject }
      .to change { Dir['*.gem'] }
      .from([])
      .to(include(match(/^nanoc-checking-.*\.gem$/)))
  end
end
