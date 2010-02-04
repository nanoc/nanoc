# nanoc 3

nanoc is a simple but very flexible static site generator written in Ruby.
It operates on local files, and therefore does not run on the server. nanoc
"compiles" the local source files into HTML (usually), by evaluating eRuby,
Markdown, etc.

## Documentation

The [nanoc3 web site](http://nanoc.stoneship.org) contains a few useful
resources to help you get started with nanoc:

* The [tutorial](http://nanoc.stoneship.org/tutorial)
* The [manual](http://nanoc.stoneship.org/manual)
* The [migration guide](http://nanoc.stoneship.org/migrating)

It is probably also worth checking out and perhaps subscribing to the
discussion groups:

* The [discussion group in English](http://groups.google.com/group/nanoc)
* The [discussion group in Spanish](http://groups.google.com/group/nanoc-es)

### Source Code Documentation

The source code is structured in a few directories:

* `bin` contains the commandline tool aptly named `nanoc3`
* `lib`
  * `nanoc3`
    * `base` contains the bare essentials necessary for nanoc to function
    * `cli` contains the commandline interface
    * `data_sources` contains the standard data sources (Nanoc3::DataSource
      subclasses), such as the filesystem data source
    * `helpers` contains helpers, which provide functionality some sites
      may find useful, such as the blogging and tagging helpers
    * `extra` contains stuff that is not needed by nanoc itself, but which may
      be used by helpers, data sources, filters or VCSes.
    * `filters` contains the standard filters (Nanoc3::Filter subclasses) such
      as ERB, Markdown, Haml, ...
* `test` contains testing code, structured in the same way as lib/nanoc

The namespaces (modules) are organised like this:

* `Nanoc3` is the namespace for everything nanoc-related (obviously). The
  classes in `lib/nanoc3/base` are part of this module (not `Nanoc3::Base`)
  * `CLI` containing everything related to the commandline tool.
  * `DataSources` contains the data sources
  * `Helpers` contains the helpers
  * `Extra` contains useful stuff not needed by nanoc itself
  * `Filters` contains the (textual) filters

The central class in nanoc is `Nanoc3::Site`, so you should start there if
you want to explore nanoc from a technical perspective.

## Dependencies

nanoc itself can be used without installing any dependencies. Some
components, however, do have dependencies:

* The **autocompiler** depends on `mime-types` and `rack`.
* For **documentation generation** you’ll need `yard`.
* For **packaging** you’ll need `rubygems` (1.3 or newer).
* For **testing** you’ll need `mocha`.

## Contributors

(In alphabetical order)

* Colin Barrett
* Dmitry Bilunov
* Brian Candler
* Chris Eppstein
* Starr Horne
* Nicky Peeters
* Christian Plessl
* Šime Ramov
* "Soryu"
* Eric Sunshine
* Dennis Sutch

Special thanks to Ale Muñoz.

## Contact

You can reach me at <denis.defreyne@stoneship.org>.
