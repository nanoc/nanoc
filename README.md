**Please take a moment and [donate](http://pledgie.com/campaigns/9282) to nanoc. A lot of time has gone into developing nanoc, and I would like to keep the current pace. Your support will ensure that nanoc will continue to improve.**

# Where did all the code go?!

Going forward, nanoc 4.0 will consist of many individual sub-projects with
clearly-defined purposes. This is in contrast to nanoc 3.x, where all plugins
were included in nanoc. Each of these sub-projects will be packaged in a gem:

* [nanoc-core](http://github.com/nanoc/nanoc-core): core logic for compiling sites
* [nanoc-cli](http://github.com/nanoc/nanoc-cli): command-line front end
* nanoc (this repository): installs nanoc-core and nanoc-cli
* [nanoc-powerpack](http://github.com/nanoc/nanoc-powerpack): installs nanoc-core, nanoc-cli, all filters, and all helpers

See [this mailinglist message](https://groups.google.com/forum/#!topic/nanoc/vtMojy3Un2I) for details on sub-projects. You can find the full list of official nanoc plugins on the [nanoc organisation GitHub page](http://github.com/nanoc).

# nanoc

nanoc is a simple but very flexible static site generator written in Ruby.
It operates on local files, and therefore does not run on the server. nanoc
“compiles” the local source files into HTML (usually), by evaluating eRuby,
Markdown, etc.

## Requirements

Ruby 1.9.x and up.

nanoc has no few dependencies on its own. Sub-projects, such as filters and
helpers, may have dependencies of their own, however.

## Installation

`gem install nanoc` or take a look at the [installation page](http://nanoc.ws/install/).

## Versioning

nanoc uses [Semantic Versioning](http://semver.org/).

## Documentation

Check out the [nanoc web site](http://nanoc.ws)!

## License

nanoc is licensed under the MIT license. For details, check out the LICENSE file.

## Support

You can get help in the following places:

* the [discussion group](http://groups.google.com/group/nanoc)
* the [#nanoc IRC channel on Freenode](irc://chat.freenode.net/#nanoc)
