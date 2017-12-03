# frozen_string_literal: true

def sub_sh(dir, cmd)
  Bundler.with_clean_env do
    Dir.chdir(dir) do
      puts "(in #{Dir.getwd})"
      sh(cmd)
    end
  end
end

namespace :nanoc do
  task(:test) { sub_sh('nanoc', 'bundle exec rake test') }
  task(:gem) { sub_sh('nanoc', 'bundle exec rake gem') }
end

namespace :nanoc_live do
  task(:test) { sub_sh('nanoc-live', 'bundle exec rake test') }
  task(:gem) { sub_sh('nanoc-live', 'bundle exec rake gem') }
end

task test: %i[nanoc:test nanoc_live:test]
task gem: %i[nanoc:gem nanoc_live:gem]
task default: :test
