# nanoc 3

nanoc is a simple but very flexible static site generator written in Ruby.
It operates on local files, and therefore does not run on the server. nanoc
“compiles” the local source files into HTML (usually), by evaluating eRuby,
Markdown, etc.

Note: This documentation looks best with Yardoc, not RDoc.

## Resources

The [nanoc web site](http://nanoc.stoneship.org) contains a few useful
resources to help you get started with nanoc:

* The [tutorial](http://nanoc.stoneship.org/tutorial)
* The [manual](http://nanoc.stoneship.org/manual)
* The [migration guide](http://nanoc.stoneship.org/migrating)

If you need assistance, the following places will help you out:

* The [discussion group](http://groups.google.com/group/nanoc)
* The [IRC channel](irc://chat.freenode.net/#nanoc)

## Source Code Documentation

The source code is located in `lib/nanoc3` and is structured in a few
directories:

* `base` contains the bare essentials necessary for nanoc to function
* `cli` contains the commandline interface
* `data_sources` contains the standard data sources ({Nanoc3::DataSource}
  subclasses), such as the filesystem data source
* `helpers` contains helpers, which provide functionality some sites
  may find useful, such as the blogging and tagging helpers
* `extra` contains stuff that is not needed by nanoc itself, but which may
  be used by helpers, data sources, filters or VCSes.
* `filters` contains the standard filters ({Nanoc3::Filter} subclasses)
  such as ERB, Markdown, Haml, ...

The namespaces (modules) are organised like this:

* {Nanoc3} is the namespace for everything nanoc-related (obviously). The
  classes in `lib/nanoc3/base` are part of this module (not `Nanoc3::Base`)
* {Nanoc3::CLI} containing everything related to the commandline tool.
* {Nanoc3::DataSources} contains the data sources
* {Nanoc3::Helpers} contains the helpers
* {Nanoc3::Extra} contains useful stuff not needed by nanoc itself
* {Nanoc3::Filters} contains the (textual) filters

The central class in nanoc is {Nanoc3::Site}, so you should start there if
you want to explore nanoc from a technical perspective.

## Dependencies

nanoc has few dependencies. It is possible to use nanoc programmatically
without any dependencies at all, but if you want to use nanoc in a proper way,
you’ll likely need some dependencies:

* The **commandline frontend** depends on `cli`.
* The **autocompiler** depends on `mime-types` and `rack`.
* Filters and helpers likely have dependencies on their own too.

If you’re developing for nanoc, such as writing custom filters or helpers, you
may be interested in the development dependencies:

* For **documentation generation** you’ll need `yard`.
* For **packaging** you’ll need `rubygems` (1.3 or newer).
* For **testing** you’ll need `mocha` and `minitest`.

## Contributors

(In alphabetical order)

* Ben Armston
* Colin Barrett
* Dmitry Bilunov
* Brian Candler
* Chris Eppstein
* Felix Hanley
* Starr Horne
* Tuomas Kareinen
* Nicky Peeters
* Christian Plessl
* Šime Ramov
* Xavier Shay
* “Soryu”
* Eric Sunshine
* Dennis Sutch

Special thanks to Ale Muñoz.

## Contact

You can reach me at <denis.defreyne@stoneship.org>.
