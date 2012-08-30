# nanoc 3

nanoc is a simple but very flexible static site generator written in Ruby.
It operates on local files, and therefore does not run on the server. nanoc
“compiles” the local source files into HTML (usually), by evaluating eRuby,
Markdown, etc.

Note: This documentation looks best with Yardoc, not RDoc.

## Resources

The [nanoc web site](http://nanoc.stoneship.org) contains a few useful
resources to help you get started with nanoc. If you need further assistance,
the following places will help you out:

* The [discussion group](http://groups.google.com/group/nanoc)
* The [IRC channel](irc://chat.freenode.net/#nanoc)

## Versioning

nanoc uses [Semantic Versioning](semver.org).

## Source Code Documentation

The source code is located in `lib/nanoc` and is structured in a few
directories:

* `base` contains the bare essentials necessary for nanoc to function
  * `source_data` contains raw, uncompiled content that will be compiled
  * `result_data` contains the compiled content
  * `compilation` contains the compilation functionality
* `cli` contains the commandline interface
* `data_sources` contains the standard data sources ({Nanoc::DataSource}
  subclasses), such as the filesystem data source
* `extra` contains stuff that is not needed by nanoc itself, but which may
  be used by helpers, data sources, filters or VCSes.
* `filters` contains the standard filters ({Nanoc::Filter} subclasses)
  such as ERB, Markdown, Haml, …
* `helpers` contains helpers, which provide functionality some sites
  may find useful, such as the blogging and tagging helpers
* `tasks` contains rake tasks that perform a variety of functions such as
  validating HTML and CSS, uploading compiled files, …

The namespaces (modules) are organised like this:

* {Nanoc} is the namespace for everything nanoc-related (obviously). The
  classes in `lib/nanoc/base` are part of this module (not `Nanoc::Base`)
* {Nanoc::CLI} containing everything related to the commandline tool.
* {Nanoc::DataSources} contains the data sources
* {Nanoc::Helpers} contains the helpers
* {Nanoc::Extra} contains useful stuff not needed by nanoc itself
* {Nanoc::Filters} contains the (textual) filters

The central class in nanoc is {Nanoc::Site}, so you should start there if
you want to explore nanoc from a technical perspective.

## Dependencies

nanoc has few dependencies. It is possible to use nanoc programmatically
without any dependencies at all, but if you want to use nanoc in a proper way,
you’ll likely need some dependencies:

* The **commandline frontend** depends on `cri`.
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
* Matt Keveney
* Kevin Lynagh
* Nikhil Marathe
* Daniel Mendler
* Ale Muñoz
* John Nishinaga
* Nicky Peeters
* Christian Plessl
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
