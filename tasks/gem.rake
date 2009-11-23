# encoding: utf-8

namespace :pkg do

  begin
    require 'jeweler'
    Jeweler::Tasks.new do |s|
      s.name        = "nanoc3"
      s.summary     = "a web publishing system written in Ruby for building small to medium-sized websites."
      s.description = "a web publishing system written in Ruby for building small to medium-sized websites."
      s.homepage    = 'http://nanoc.stoneship.org/'

      s.platform    = Gem::Platform::RUBY
      s.version     = Nanoc3::VERSION

      s.authors     = [ 'Denis Defreyne' ]
      s.email       = "denis.defreyne@stoneship.org"

      s.files       = FileList['[A-Z]*', 'lib/**/*']

      s.post_install_message  = <<EOS
------------------------------------------------------------------------------
Thanks for installing nanoc 3.1! Here are some resources to help you get
started:

* The tutorial at <http://nanoc.stoneship.org/tutorial/>
* The manual at <http://nanoc.stoneship.org/manual/>
* The discussion group at <http://groups.google.com/group/nanoc>

Because nanoc 3.1 has quite a few new features, be sure to check out the nanoc
blog at <http://nanoc.stoneship.org/blog/> for details about this release.

Enjoy!
------------------------------------------------------------------------------
EOS

      s.required_ruby_version = '>= 1.8.6'
      s.add_dependency('cri', '>= 1.0.0')
    end
  rescue LoadError
    warn "Jeweler (or a dependency) is not available. Install it with `gem install jeweler`"
  end

end
