# frozen_string_literal: true

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

def sub_sh(dir, cmd)
  Bundler.with_clean_env do
    Dir.chdir(dir) do
      puts "======= entering ./#{dir}/"
      puts
      sh(cmd)
      puts
      puts "======= exiting ./#{dir}/"
    end
  end
end

packages = %w[
  nanoc
  nanoc-core
  nanoc-cli
  nanoc-checking
  nanoc-deploying
  nanoc-external
  nanoc-live
  nanoc-spec
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

task :summary do
  versions = {}
  dependencies = {}

  packages.each do |name|
    gemspec = Bundler.rubygems.find_name(name).first

    dependencies[name] =
      gemspec
      .dependencies
      .select { |d| d.name.match?(/nanoc/) }
    versions[name] = gemspec.version
  end

  name_sets =
    versions
    .keys
    .partition { |name| %w[nanoc nanoc-core nanoc-cli].include?(name) }
    .map(&:sort)

  puts '━━━ VERSIONS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
  puts
  name_length = versions.keys.map(&:size).max
  name_sets.each_with_index do |names, idx|
    puts if idx.positive?
    names.each do |name|
      puts(format("    %#{name_length}s   %s", name, versions[name]))
    end
  end
  puts

  puts '━━━ DEPENDENCIES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
  puts
  name_sets.flatten.each do |name|
    puts(format('    %-s %s', name, '╌' * (40 - name.length)))
    dependencies[name].sort_by(&:name).each do |dependency|
      puts(format("      %-#{name_length}s   %s", dependency.name, dependency.requirement))
    end
    puts
  end
end

task default: %i[test rubocop]
