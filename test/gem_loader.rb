# encoding: utf-8

begin
  require 'rubygems'

  gemspec = File.expand_path("nanoc.gemspec", Dir.pwd)
  Gem::Specification.load(gemspec).dependencies.each do |dep|
    gem dep.name, *dep.requirement.as_list
  end
rescue LoadError => e
end
