[![Build Status](https://travis-ci.org/nanoc/nanoc.png)](https://travis-ci.org/nanoc/nanoc)
[![Code Climate](https://codeclimate.com/github/nanoc/nanoc.png)](https://codeclimate.com/github/nanoc/nanoc)
[![Coverage Status](https://coveralls.io/repos/nanoc/nanoc/badge.png?branch=master)](https://coveralls.io/r/nanoc/nanoc)

**Please take a moment and [donate](http://pledgie.com/campaigns/9282) to nanoc. A lot of time has gone into developing nanoc, and I would like to keep the current pace. Your support will ensure that nanoc will continue to improve.**

# nanoc

nanoc is a simple but very flexible static site generator written in Ruby.
It operates on local files, and therefore does not run on the server. nanoc
“compiles” the local source files into HTML (usually), by evaluating eRuby,
Markdown, etc.

Note: This documentation looks best with Yardoc, not RDoc.

## Requirements

Ruby 1.9.x and up.

nanoc has few dependencies. It is possible to use nanoc programmatically
without any dependencies at all, but if you want to use nanoc in a proper way,
you’ll likely need some dependencies:

* The **commandline frontend** depends on `cri`.
* Filters and helpers likely have dependencies on their own too.

If you’re developing for nanoc, such as writing custom filters or helpers, you
may be interested in the development dependencies:

* For **documentation generation** you’ll need `yard`.
* For **testing** you’ll need `mocha` and `minitest`.

## Installation

`gem install nanoc` or take a look at the [installation page](http://nanoc.ws/install/).

## Tests

Running `rake` will run all the tests. To run a subset, use specific tasks, e.g. `rake test:filters` for running filter tests only.

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

## Contributors

(In alphabetical order)

* Ben Armston
* Colin Barrett
* Bil Bas
* Dmitry Bilunov
* Fabian Buch
* Devon Luke Buchanan
* Stefan Bühler
* Dan Callahan
* Brian Candler
* Jack Chu
* Michal Cichra
* Zaiste de Grengolada
* Vincent Driessen
* Chris Eppstein
* Jeff Forcier
* Riley Goodside
* Felix Hanley
* Justin Hileman
* Starr Horne
* Daniel Hofstetter
* Tuomas Kareinen
* Greg Karékinian
* Matt Keveney
* Kevin Lynagh
* Go Maeda
* Nikhil Marathe
* Daniel Mendler
* Stuart Montgomery
* Ale Muñoz
* John Nishinaga
* Gregory Pakosz
* Nicky Peeters
* Christian Plessl
* Damien Pollet
* Šime Ramov
* Xavier Shay
* Arnau Siches
* “Soryu”
* Eric Sunshine
* Dennis Sutch
* Takashi Uchibe
* Matthias Vallentin
* Ruben Verborgh
* Scott Vokes
* Toon Willems

## Contact

You can reach me at <denis.defreyne@stoneship.org>.
