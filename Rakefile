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

task :needs_release do
  tags = `git tags`.lines.map(&:chomp).map { |t| t.match?(/\A\d/) ? 'nanoc-v' + t : t }
  tags_by_base_name = tags.group_by { |t| t[/\A.*(?=-v\d)/] }.select { |(base_name, _tags)| base_name }
  versions_by_base_name = tags_by_base_name.transform_values { |list| list.map { |nv| nv.match(/\A.*-v(\d.*)/) }.compact.map { |m| Gem::Version.new(m[1]) } }
  last_version_by_base_name = versions_by_base_name.transform_values(&:max)

  name_length = last_version_by_base_name.keys.map(&:size).max
  last_version_by_base_name.keys.sort.each do |base_name|
    last_version = last_version_by_base_name[base_name]
    dir = base_name
    tag = base_name == 'nanoc' ? last_version.to_s : base_name + '-v' + last_version.to_s
    diff = `git diff --stat #{tag} #{dir}`
    needs_release = diff.match?(/\d+ files changed/)

    text = needs_release ? 'needs release' : 'up to date'
    color = needs_release ? "\e[33m" : "\e[32m"
    puts(
      format(
        "%-#{name_length}s   \e[1m%s%s\e[0m",
        base_name,
        color,
        text,
      ),
    )
  end
end

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
