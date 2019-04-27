# frozen_string_literal: true

describe 'nanoc.gem', chdir: false, stdio: true do
  subject do
    TTY::Command.new.run('gem build nanoc.gemspec')
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
      .to(include(match(/^nanoc-.*\.gem$/)))
  end
end
