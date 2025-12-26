# frozen_string_literal: true

describe 'nanoc-dart-sass.gem', :stdio, chdir: false do
  subject(:build_gem) do
    TTY::Command.new.run('gem build nanoc-dart-sass.gemspec')
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
      .to(include(match(/^nanoc-dart-sass-.*\.gem$/)))
  end
end
