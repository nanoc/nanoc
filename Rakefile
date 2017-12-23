# frozen_string_literal: true

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

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
  task(:rubocop) { sub_sh('nanoc', 'bundle exec rake rubocop') }
end

namespace :nanoc_external do
  task(:test) { sub_sh('nanoc-external', 'bundle exec rake test') }
  task(:rubocop) { sub_sh('nanoc-external', 'bundle exec rake rubocop') }
end

namespace :nanoc_live do
  task(:test) { sub_sh('nanoc-live', 'bundle exec rake test') }
  task(:rubocop) { sub_sh('nanoc-live', 'bundle exec rake rubocop') }
end

task test: %i[nanoc:test nanoc_external:test nanoc_live:test]
task gem: %i[nanoc:gem nanoc_external:gem nanoc_live:gem]

task default: %i[test rubocop]
