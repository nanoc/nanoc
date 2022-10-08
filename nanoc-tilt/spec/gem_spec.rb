# frozen_string_literal: true

describe 'nanoc-tilt.gem', chdir: false, stdio: true do
  subject(:build_gem) do
    TTY::Command.new.run('gem build nanoc-tilt.gemspec')
  end

  around do |ex|
    Dir['*.gem'].each { |f| FileUtils.rm(f) }
    ex.run
    Dir['*.gem'].each { |f| FileUtils.rm(f) }
  end

  it 'builds gem' do
    expect { build_gem }
      .to change { Dir['*.gem'] }
      .from([])
      .to(include(match(/^nanoc-tilt-.*\.gem$/)))
  end
end
