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

packages = %w[
  nanoc
  nanoc-core
  nanoc-cli
  nanoc-external
  nanoc-live
  guard-nanoc
]

packages.each do |package|
  namespace(package.tr('-', '_')) do
    task(:test) { sub_sh(package, 'bundle exec rake test') }
    task(:rubocop) { sub_sh(package, 'bundle exec rake rubocop') }
  end
end

task test: packages.map { |p| p.tr('-', '_') + ':test' }
task gem: packages.map { |p| p.tr('-', '_') + ':gem' }

task default: %i[test rubocop]
