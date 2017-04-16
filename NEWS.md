# Nanoc news

## 4.7.7 (2017-04-16)

Enhancements:

* Added `--diff` option to `compile` command as a one-time alternative to `enable_output_diff` (#1155)
* Sped up incremental compilation (#1156, #1157)

## 4.7.6 (2017-04-15)

Enhancements:

* Added support for `:html5` in `relativize_paths` and `colorize_syntax` filters (#1153)

## 4.7.5 (2017-04-01)

Fixes:

* Made `--verbose` be recognised when calling `nanoc` without subcommand (#1145, #1146)

Enhancements:

* Made `show-data` print all outdatedness reasons, not just the first (#1142)
* Sped up `@items.find_all` (#1147)

## 4.7.4 (2017-03-29)

Enhancements:

* Made attribute dependencies cause outdatedness less often (#1136, #1137, #1138)
* Improved speed of Rules file handling (#1140)

## 4.7.3 (2017-03-26)

Fixes:

* Fixed an issue which could cause a missing file for a snapshot that is not `:last` not to be regenerated when compiling (#1134, #1135)

## 4.7.2 (2017-03-21)

Fixes:

* Fixed crash when calling `#raw_path` in the Checks file (#1130, #1131)

## 4.7.1 (2017-03-19)

Fixes:

* Fixed issue with `:xsl` filter not recompiling when it should (#924, #1127)

Enhancements:

* Made `compile --verbose` print percentiles rather than averages (#1122)
* Improved dependency cycle error messages (#1123)

## 4.7 (2017-03-15)

Features:

* Added `:erubi` filter (#1103) [Jan M. Faber]
* Added `write ext: 'something'` shortcut (#1079)

## 4.6.4 (2017-03-10)

Fixes:

* Fixed issue where `compile --verbose` would show misleading timing information (#1113)

## 4.6.3 (2017-03-05)

Fixes:

* Fixed `Errno::ENOENT` crash (#1094, #1109)
* Fixed undefined method `#reverse_each` crash (#1107, #1108)
* Fixed compilation speed issue introduced in 4.6.2 (#1106)

## 4.6.2 (2017-03-04)

Fixes:

* Fixed crash in `#binary?` (#1082, #1083, #1084)
* Fixed issue which would cause the file referenced by `#raw_path` not to exist (#1097, #1099)

Enhancements:

* Allowed calling `#write` multiple times in the same rule (#1037, #1085)
* Changed the `html` check to use validator.nu (#1104)

## 4.6.1 (2017-01-29)

Fixes:

* Fixed table formatting in `compile --verbose` (#1074) [Hugo Peixoto]

Enhancements:

* Reduced memory usage (#1075, #1076, #1077, #1078)

## 4.6 (2017-01-22)

Features:

* Made `#content_for` accept a string as well as a block, to allow setting captured content outside of ERB (#1066, #1073)
* Added `#raw_content=` to items and layouts during preprocessing (#1057)
* Added `#snapshot?` to item rep views (#1056)

Enhancements:

* Prevented useless recompilations when switching Nanoc environments (#1070, #1071)

## 4.5.4 (2017-01-16)

Fixes:

* Fixed issue with site not being recompiled fully when switching between environments (#1067, #1069)

## 4.5.3 (2017-01-15)

Fixes:

* Fixed “Fixnum is deprecated” message (#1061, #1062)
* Fixed `:pre` snapshot not being created for items that are not laid out (#1064, #1065)

## 4.5.2 (2017-01-11)

Fixes:

* Fixed handling of periods in full identifiers (#1022, #1059)
* Fixed “cannot layout binary items” error message (#1058)
* Fixed escaping of URLs in sitemaps (#1052, #1054)

## 4.5.1 (2017-01-09)

Fixes:

* Fixed crash when Nokogiri is not installed (#1053)

## 4.5 (2017-01-09)

Features:

* Added Git deployer (#997)

## 4.4.7 (2017-01-05)

Fixes:

* Fixed issue that caused an item not to be considered outdated when only the mtime has changed (#1046)
* Removed stray `require 'parallel'` which could break the `external_links` check (#1051) [Cédric Boutillier]

Enhancements:

* Made Nanoc not recompile compiled items after an exception occurs (#1044)

## 4.4.6 (2016-12-28)

Fixes:

* Fixed issue where `#compiled_content` would not return the correct content (#1040, #1041)

## 4.4.5 (2016-12-24)

Fixes:

* Prevented stale data from making it into the checksum store and thereby blowing up in memory (#1004, #1027)
* Fixed slow recompile after adding many items to a site (#1028)
* Fixed wrong capturing helper output when the output field separator (`$,`) is set
* Fixed issue that could cause items with multiple reps not to be recompiled when needed (#1031, #1032)
* Fixed error when fetching textual content of item whose `:last` snapshot is binary (#1035, #1036)

## 4.4.4 (2016-12-19)

Enhancements:

* Improved speed of incremental compilations (#1017, #1019, #1024)

## 4.4.3 (2016-12-17)

Fixes:

* Prevented stale data from making it into the compiled content cache and thereby blowing up in memory (#1004, #1013)
* Fixed “about” and “IRC channel” links in default site
* Fixed accuracy of `<updated>` in Atom feed (use most recent `updated_at` or `created_at`) (#1007, #1014)

Enhancements:

* Added support for non-legacy identifiers in `#breadcrumbs_trail` (#1010, #1011)
* Defined checksum for `Nanoc::Int::Context` to make outdatedness checker more precise (#1008, #1012)
* Made Nanoc raise an error when item reps are routed to a path that does not start with a slash (#1015, #1016)

## 4.4.2 (2016-11-27)

Fixes:

* Fixed “Maximum call stack size exceeded” issue in the `less` filter (#1001)
* Fixed issue that could cause the `less` filter to not generate all necessary dependencies (#1003)

Enhancements:

* Improved the way that the crash log displays the item rep that is being compiled (#1000)

## 4.4.1 (2016-11-21)

Fixes:

* Fixed an issue where the `xsl` filter would not generate a correct dependency on the layout (#996)

Enhancements:

* Made `view` command use index filenames specified in the `index_filenames` site configuration attribute (#998)

## 4.4 (2016-11-19)

Features:

* Added support for Nanoc environments (#859)

## 4.3.8 (2016-11-18)

Enhancements:

* Improved support for Rouge 1.x and 2.x (#880) [Rémi Barraquand]
* Added `#include` to the `nanoc shell` command (#973)
* Improved speed of full and incremental compilations (#977, #985)

Fixes:

* Made routing rules and `#write` calls accept an identifier, and not just a string (#976)
* Removed GC speed-up hacks, which became counterproductive in Ruby 2.2 (#975)
* Fixed issue which caused items to be always recompiled if `rep`/`item_rep` or `self` are used in those items’ rules (#982)

## 4.3.7 (2016-10-29)

Fixes:

* Fixed issue with `show-data` and `show-rules` commands not showing all data (#970) [Chris Chapman]

Enhancements:

* Improved speed of `compile` command (#968)
* Improved speed of `prune` command (#969)
* Made kramdown warnings include affected item rep (#967) [Gregory Pakosz]
* Made kramdown warnings configurable (#967) [Gregory Pakosz]

## 4.3.6 (2016-10-23)

Fixes:

* Made legacy patterns properly support full identifiers (#957)
* Fixed timezone issues in `#to_iso8601_date` (#961)
* Fixed error when accessing item (rep) paths in shell command (#963)
* Fixed issue that caused `#path` to be nil inside compilation rules (#964)
* Made `__FILE__` in Checks file be a absolute path (#966)

Enhancements:

* Made the command line write status information to stderr, not stdout (#958)

## 4.3.5 (2016-10-14)

Fixes:

* Handle `form/@action` in `relativize_paths` filter (#950) [Lorin Werthen]

Experimental features:

* `profiler`: adds `--profile` option to the `compile` command to profile compilation (#903)
* `environments`: adds support for Nanoc environments (#859)

## 4.3.4 (2016-10-02)

Fixes:

* Fixed compilation crash when output directory does not exist and auto-pruning is enabled (#948, #949)

## 4.3.3 (2016-09-26)

Fixes:

* Fixed issue causing `Bundler::GemfileNotFound` to be thrown (#936) [Lorin Werthen]
* Fixed issue when replacing a directory with a file or vice versa (#942, #946)

Enhancements:

* Modified the `compile` command to allow specifying the deploy target as argument (#945)

## 4.3.2 (2016-08-23)

Identical to 4.3.1, but with corrected release notes.

## 4.3.1 (2016-08-23)

Fixes:

* Fixed “outdatedness of LayoutView” error (#927, #931)
* Fixed bug causing some checks not to appear in `nanoc check --list` (#928, #930)
* Fixed `@item`, … not being accessible in filters defined with `Nanoc::Filter.define` (#932, #934)

## 4.3 (2016-08-21)

Features:

* Added `Nanoc::Filter.define`, to easily define filters (#895)
* Made the `nanoc` Gemfile group be auto-required when Nanoc starts (#910) [whitequark]

## 4.2.4 (2016-07-24)

Fixes:

* Fixed `UnmetDependency` errors in postprocessor (#913, #917)

Enhancements:

* Sped up Nanoc by not releasing cache memory as quickly (#902)
* Let `internal_links` check also verify resource paths, such as scripts and images (#912) [Lorin Werthen]
* Improved error reporting for errors in the Rules file (#908, #914, #915, #916)
* Removed `win32console` support, as it’s deprecated and causing problems (#900, #918)

## 4.2.3 (2016-07-03)

Fixes:

* Fixed issue with `#inspect` raising a `WeakRef::RefError` (#877, #897)

Enhancements:

* Sped up compiler (#894)
* Improved `#inspect` output of some classes (#896)
* Deprecated `Item#modified` and replaced it with `Item#modified_reps` (#898)

## 4.2.2 (2016-07-02)

Fixes:

* Fixed confusing “invalid prefix” error message (#873, #879)
* Ensured filter arguments are frozen, to prevent outdatedness checker errors (#881, #886)
* Fixed issue with dependencies of items generated in the preprocessor not being tracked (#885, #891, #893)

Enhancements:

* Added specific handling for `Sass::Importers::Filesystem` in the checksummer, which should reduce unnecessary recompiles in sites using Compass (#866, #884)
* Improved speed of checksummer (#864, #887)

## 4.2.1 (2016-06-19)

Fixes:

* Fixed an occasional `WeakRef::RefError` (#863, #865)
* Fixed `show-data` command not running preprocessor (#867, #870)

## 4.2 (2016-06-04)

Enhancements:

* Dropped Ruby 2.1 support (#856)

This release also includes the changes from 4.2.0b1.

## 4.1.6 (2016-04-17)

Fixes:

* Strip index.html only if it is a full component (#850, #851)
* Force UTF-8 for item rep paths (#837, #852)

## 4.2.0b1 (2016-04-17)

Features:

* Allow creating items and layouts with a pre-calculated checksum (#793) [Ruben Verborgh]
* Allow lazy-loading item/layout content and attributes (#794) [Ruben Verborgh]
* Added `exclude_origins` configuration option to internal links checker (#847)
* Added `ChildParent` helper, providing `#children_of` and `#parent_of` (#849)

Enhancements:

* Made `#html_escape` raise an appropriate error when the given argument is not a String (#840) [Micha Rosenbaum]
* Improved memory usage of memoized values by using weak refs (#846)

## 4.1.5 (2016-03-24)

Fixes:

* Fixed crash in `show-data` command (#833, #835)
* Fixed preprocessor not being invoked before running checks (#841, #842)

## 4.1.4 (2016-02-13)

Fixes:

* Added missing `Configuration#key?` method (#815, #820)
* Made output diff use correct snapshot rather than `:last` (#813, #814)

Enhancements:

* Sped up item resolution in Sass filter (#821)
* Made `#link_to` more resilient to unsupported argument types (#816, #819)

## 4.1.3 (2016-01-30)

Fixes:

* Fixed crash in `check` command when the subject of an issue is nil (#804, #811)
* Made stale check not ignore non-final snapshot paths (#809, #810)

## 4.1.2 (2016-01-16)

Fixes:

* Made @-variables (e.g. `@items`) report their frozenness properly, so that optimisations based on frozenness work once again (#795, #797)
* Removed environment from `crash.log` to prevent leaking sensitive information (#798, #800)

Enhancements:

* Removed redundant checksum calculation (#789) [Ruben Verborgh]

## 4.1.1 (2015-12-30)

Fixes:

* Fixed preprocessor not being run before check/deploy/prune commands (#763, #784, #787, #788)

Enhancements:

* Made `#breadcrumbs_trail` explicitly fail when using full identifiers (#781, #783)

## 4.1 (2015-12-18)

Fixes:

* Fixed crash when attempting to `#puts` an object that’s not a string (#778)
* Made pruner not prune away files from routes defined for custom snapshots (#779)
* Wrapped `@layout` in a layout view (#773)

Enhancements:

* Added a base path to the Checks file, so that it supports `#require_relative` (#774)

This release also includes the changes from 4.1.0a1 to 4.1.0rc2.

## 4.1.0rc2 (2015-12-13)

Fixes:

* Fixed children of the root item not having a parent (#769, #770)

Enhancements:

* Made `#path`, `#compiled_content` and `#reps` unavailable during pre-processing, compilation and routing, because they do not make sense in these contexts (#571, #767, #768)

## 4.1.0rc1 (2015-12-12)

Fixes:

* Fixed `@item.compiled_content` in a layout raising an exception (#761, #766)

## 4.1.0b1 (2015-12-11)

Fixes:

* Fixed issue with `:pre` snapshot not being generated properly (#764)

Enhancements:

* Updated default site to use `#write` (#759)

## 4.1.0a1 (2015-12-05)

Features:

* Added `postprocess` block (#726) [Garen Torikian]
* Added `#write` compilation instruction and `path` option to `#snapshot` (#753)

Fixes:

* Fixed crash when printing non-string object (#712) [Garen Torikian]
* Removed English text from `#link_to` helper (#736) [Lucas Vuotto]

Enhancements:

* Allowed excluding URLs from external links check (#686) [Yannick Ihmels]
* Added `atom` to list of text extensions (#657) [Yannick Ihmels]
* Added `#each` to `Nanoc::ConfigView` (#705) [Garen Torikian]
* Made `#attribute_to_time` handle `DateTime` (#717) [Micha Rosenbaum]
* Added `Identifier#components` (#677)
* Added `:existing` option to `#content_for` (can be `:error`, `:overwrite` and `:append`) (#744)

## 4.0.2 (2015-11-30)

Fixes:

* Properly set required Ruby version to 2.1 in the gem specification (#747)
* Fixed issue with CLI commands not being loaded as UTF-8 (#742)
* Added missing `#identifier=` method to items and layouts during preprocessing (#750)

Enhancements:

* Let attempts to fetch an item rep by number, rather than symbol, fail with a meaningful error (#749)

## 4.0.1 (2015-11-28)

Fixes:

* Fixed params documentation for :rdiscount filter (#722)
* Fixed crash when comparing item rep views (#735, #738)

Enhancements:

* Lowered minimum required Ruby version from 2.2 to 2.1 (#732)

## 4.0 (2015-11-07)

Enhancements:

* `#parent` and `#children` now raise an exception when used on items with a non-legacy identifier (#710)

This release also includes the changes from 4.0.0a1 to 4.0.0rc3.

## 4.0.0rc3 (2015-09-20)

Features:

* Added `Identifier#without_exts` and `Identifier#exts` (#644, #696) [Rémi Barraquand]
* Added `DocumentView#attributes` (#699, #702)

Fixes:

* Fixed issue when comparing document views (#680, #693)

Enhancements:

* Made `#base_url` argument in `#tags_for` optional (#687) [Croath Liu]
* Allowed `IdentifiableCollection#[]` to be passed an identifier (#681, #695)
* Improved `Pattern.from` error message (#683, #692)
* Let default site use a direct link to the stylesheet (#685, #701)

Changes:

* Removed `Identifier#with_ext` because its behavior was confusing (#697, #700)
* Disallowed storing document (views) in attributes (#682, #694)

## 4.0.0rc2 (2015-07-11)

Fixes:

* Fixed broken `shell` command (#672) [Jim Mendenhall]
* Fixed absolute path check on Windows (#656)

Enhancements:

* Made Nanoc error when multiple items have the same output path (#665, #669)
* Improved error message for non-hash frontmatter (#670, #673)

Changes:

* nanoc is now called Nanoc

## 4.0.0rc1 (2015-06-21)

Fixes:

* Fixed double-wrapping of `@layout` in rendering helper (#631)
* Fixed `show-rules` command (#633)

## 4.0.0b4 (2015-06-10)

Fixes:

* Added missing `#ext` method to identifiers (#612)
* Fixed issue where identifiers would have the wrong extension (#611)
* Fixed rule context exposing entities rather than views (#614, #615)
* Fixed `#key?` and `#fetch` not being available on layout views (#618)
* Fixed `#update_attributes` not being available on mutable layout views (#619)

## 4.0.0b3 (2015-05-31)

Changes:

* Removed `filesystem_verbose` data source (#599)
* Set minimum required Ruby version to 2.2

Enhancements:

* Made `@config`, `@items` and `@layouts` available in checks (#598)
* Made `filesystem` an alias for `filesystem_unified` (#599)
* Made specific reps for an item accessible using `@item.reps[:name]` (#586, #607)
* Removed `allow_periods_in_identifiers` documentation (#605)
* Made fog deployer not upload files with identical ETags to AWS (#480, #536, #552) [Paul Boone]

Fixes:

* Made `ItemView#parent` return nil if parent is nil (#600, #602)
* Added missing `identifier_type` documentation (#604)

## 4.0.0b2 (2015-05-23)

Changes:

* Removed `ItemCollectionView#at` (#582)
* Removed support for calling `ItemCollectionView#[]` with an integer (#582)
* Renamed `identifier_style` to `identifier_type`, and made its values be `"full"` or `"legacy"` (#593)
* Renamed `pattern_syntax` to `string_pattern_type`, and made its values be `"glob"` or `"legacy"` (#593)
* Made `"full"` the default for `identifier_type` (#592, #594)
* Made `"glob"` the default for `string_pattern_type` (#592)
* Enabled auto-pruning by default for new sites (#590)

Enhancements:

* Added `--force` to `create-site` command (#580) [David Alexander]
* Made default Rules file more future-proof (#591)

Fixes:

* Fixed `LayoutCollectionView#[]` documentation (it mentioned items)
* Fixed `ItemCollectionView#[]` returning an array when passed a regex
* Fixed an issue with mutable collection views’ `#delete_if` not yielding mutable views
* Fixed an issue with collection views’ `#find_all` returning entities instead of views

## 4.0.0b1 (2015-05-14)

Changes:

* Removed tasks
* Removed several private methods in the view API
* Removed default `base_url` in tagging helper

Enhancements:

* Removed unused options from CLI
* Added `Nanoc::Identifier#without_ext`
* Made `Nanoc::Identifier#=~` work with a glob
* Added `Nanoc::LayoutCollectionView#[]`
* Allowed creation of site in current directory (#549) [David Alexander]

Fixes:

* Fixed `#passthrough` for identifiers with extensions
* Fixed rendering helper for identifiers with extensions
* Fixed filtering helper

## 4.0.0a2 (2015-05-12)

Features:

* Glob patterns (opt-in by setting `pattern_syntax` to `"glob"` in the site configuration)
* Identifiers with extensions (opt-in by setting `identifier_style` to `"full"` in the data source configuration)

Enhancements:

* Added several convenience methods to view classes (#570, #572)

See the [nanoc 4 upgrade guide](http://nanoc.ws/docs/nanoc-4-upgrade-guide/) for details.

## 4.0.0a1 (2015-05-09)

This is a major upgrade. For details on upgrading, see the [nanoc 4 upgrade guide](http://nanoc.ws/docs/nanoc-4-upgrade-guide/).

This release provides no new features, but streamlines the API and functionality, in order to easen future development, both for features and for optimisations.

## 3.8 (2015-05-04)

Features:

* Added `mixed_content` check (#542, #543) [Mike Pennisi]
* Added `commands_dirs` configuration option for specifying directories to read commands from (#475) [Gregory Pakosz]
* Added `:cdn_id` option to fog deployer for invalidating CDN objects (#451) [Vlatko Kosturjak]
* Add access to regular expressions group matches in rules (#478) [Michal Papis]
* Allow filtering the items array by regex (#458) [Mike Pennisi]

Enhancements:

* Added `:preserve_order` option to preserve order in Atom feed (#533, #534)
* Allowed accessing `:pre` snapshot from within item itself (#537, #538, #548)

Fixes:

* Allowed passing generic Pandoc options with :args (#526, #535)
* Fix crash when compiling extensionless binary items (#524, #525)
* Fix double snapshot creation error (#547)

## 3.7.5 (2015-01-12)

Enhancements:

* Allowed extra patterns to be specified in the data source configuration, so that dotfiles are no longer necessary ignored (e.g. `extra_files: ['.htaccess']`) (#492, #498) [Andy Drop, Michal Papis]
* Removed Ruby 1.8.x support ([details](https://groups.google.com/forum/#!topic/nanoc/pSL1i15EFz8)) (#517)
* Improved CSS and HTML error messages (#484, #504)
* Let kramdown filter print warnings (#459, #519)

Fixes:

* Fixed HTML class names for recent Rouge versions (#502)
* Fixed crash when using items or layouts in attributes (#469, #518)

## 3.7.4 (2014-11-23)

Enhancements:

* Made `check` command fail when output directory is missing (#472) [Mike Pennisi]
* Made external links check timeouts start small and grow (#483) [Michal Papis]
* Made code and API adhere much more closely to the Ruby style guide (#476)

Fixes:

* Fixed potential “parent directory is world writable” error (#465, #474)
* Fixed retrying requests in the external link checker (#483) [Michal Papis]
* Fixed issue with data sources not being unloaded (#491) [Michal Papis]

## 3.7.3 (2014-08-31)

Fixes:

* Fixed issue which caused metadata sections not be recognised in files that use CRLF line endings (#470, #471) [Gregory Pakosz]

## 3.7.2 (2014-08-17)

Fixes:

* Fixed broken links to the now defunct RubyForge (#454, #467)
* Fixed crash when Gemfile is missing but Bundler is installed (#464)
* Made filesystem data source not strip any whitespace (#463) [Gregory Pakosz]

Enhancements:

* Fixed issue which could cause items to be unnecessarily marked as outdated (#461) [Gregory Pakosz]
* Prevented binary layouts from being generated (#468) [Gregory Pakosz]

## 3.7.1 (2014-06-16)

Fixes:

* Fixed bug which would cause nanoc to crash if no Gemfile is present (#447, #449)

## 3.7 (2014-06-08)

New features:

* Allowed excluding links from the internal links check (`@config[:checks][:internal_links][:exclude]`) (#242) [Remko Tronçon]
* Added Rouge syntax coloring filter (#398) [Guilherme Garnier]
* Backported `after_setup` from nanoc 4 to make it easier to create CLI plugins (#407) [Rémi Barraquand]
* Make lib dirs configurable using `lib_dirs` config attribute (#424) [Gregory Pakosz]
* Added support for setting parent config dir using `parent_config_file` config attribute (#419) [Gregory Pakosz]

Enhancements:

* Added `:with_toc` support to RedCarpet (#222, #232)
* Added `slim` to the list of text extensions (#316)
* Made `content/` and `layouts/` dirs configurable (#412) [Gregory Pakosz]
* Allowed included rules files to have their own preprocess block (#420) [Gregory Pakosz]

Fixes:

* Fixed bug which caused temporary directories not to be removed (#440, #444)

## 3.6.11 (2014-05-09)

Identical to 3.6.10 but published with corrected release notes.

This release was previously known as 3.6.10.1, but was renamed due to incompatibilities with the Semantic Versioning specification.

## 3.6.10 (2014-05-09)

Fixes:

* Fixed occasional "no such file" error on JRuby (#422)
* Prevented multiple items and layouts from having the same identifier (#434, #435)

Enhancements:

* Set default encoding to UTF-8 (#428)
* Improved checksummer to reduce number of unnecessary recompiles (#310, #431)
* Disabled USR1 on JRuby in order to suppress warning (#425, #426)
* Made pandoc filter argument passing more generic (#210, #433)

## 3.6.9 (2014-04-15)

Fixes:

* Fixed path to default stylesheet (#410, #411)
* Improved reliability of piping from/to external processes in JRuby (#417)
* Added workaround for “cannot modify” errors when using Nokogiri on JRuby (#416)
* Made corrupted cached data auto-repair itself if possible (#409, #418)

## 3.6.8 (2014-03-22)

Fixes:

* Fixed issue with missing compilation durations (#374, #379)
* Made XSL filter transform item rather than layout (#399, #401) [Simon South]
* Made XSL filter honor omit-xml-declaration (#403, #404) [Simon South]
* Removed "see full crash log" line from crash log (#397, #402)

Enhancements:

* Added warning when multiple preprocessors are defined (#389)
* Improve stylesheet handling in default site (#339, #395)

## 3.6.7 (2013-12-09)

Fixes:

* Made Handlebars filter usable outside layouts (#346, #348)
* Fixed ANSI color support on Windows (#352, #356)
* Made fog deployer handle prefixes properly (#351) [Oliver Byford]
* Fixed crash in watcher (#358)
* Fixed huge durations when showing skipped items after compilation (#360, #364)
* Fixed output of `--verbose` compilation statistics (#359, #365)
* Fixed issue with Sass files not recompiling (#350, #370)

Enhancements:

* Fixed Windows compatibility issues in test suite (#353) [Raphael von der Grün]
* Hid deprecated `autocompile` and `watch` commands in help
* Made CLI swallow broken pipe errors when piping to a process that terminates prematurely (#318, #369)

## 3.6.6 (2013-11-08)

Enhancements:

* Reduced number of dependencies generated by Sass filter (#306) [Gregory Pakosz]
* Recognised lowercase `utf` in language value (e.g. `en_US.utf8`) as being UTF-8 (#335, #338)
* Set [Thin](http://code.macournoyer.com/thin/) as the default server for `nanoc view` (#342, #345)
* Removed watcher section from the default configuration file (#343, #344)

Fixes:

* Prevented capturing helper from erroneously compiling items twice (#331, #337)

## 3.6.5 (2013-09-29)

Fixes:

* Fixed bug which could cause incorrect dependencies to be generated in some cases (#329)
* Fixed handling of index filenames when allowing periods in identifiers (#330)

## 3.6.4 (2013-05-29)

Enhancements:

* Deprecated `watch` and `autocompile` commands in favour of [`guard-nanoc`](https://github.com/nanoc/guard-nanoc)

Fixes:

* Fixed bug which could cause the `tmp/` dir to blow up in size
* Unescaped URLs when checking internal links

## 3.6.3 (2013-04-24)

Fixes:

* Added support for growlnotify on Windows (#253, #267)
* Fixed bug which caused the external links checker to ignore the query string (#279, #297)
* Removed weird treatment of `DOCTYPE`s in the `relativize_paths` filter (#296)
* Fixed CodeRay syntax coloring on Ruby 2.0
* Silenced "Could not find files for the given pattern(s)" message on Windows (#298)
* Fixed issue which could cause `output.diff` not to be generated correctly (#255, #301)
* Let filesystem and static data sources follow symlinks (#299, #302)
* Added compatibility with Listen 1.0 (#309)
* Let `#passthrough` in Rules work well with the static data source (#251) [Gregory Pakosz]
* Made timing information be more accurate (#303)

## 3.6.2 (2013-03-23)

Fixes:

* Removed the list of available deployers from the `deploy` help text and moved
  them into a new `--list-deployers` option [Damien Pollet]
* Fixed warning about `__send__ `and `object_id` being redefined on Ruby
  1.8.x [Justin Hileman]

Enhancements:

* Added possible alternative names for the `Checks` file for consistency with
  the `Rules` file: `Checks.rb`, `checks`, `checks.rb` [Damien Pollet]
* Made sure unchanged files never have their mtime updated [Justin Hileman]
* Made link checker retry 405 Method Not Allowed results with GET instead of
  HEAD [Daniel Hofstetter]

## 3.6.1 (2013-02-25)

Fixes:

* Fixed bug which could cause the Sass filter to raise a load error [Damien Pollet]
* Fixed warnings about `__send__` and `object_id` being redefined [Justin Hileman]
* Made `files_to_watch` contain `nanoc.yaml`, not `config.yaml` by default

## 3.6 (2013-02-24)

Features:

* Added `sync` command, allowing data sources to update local caches of
  external data [Justin Hileman]
* Added `#ignore` compiler DSL method
* Allowed accessing items by identifier using e.g. `@items['/about/']`
* Added `shell` command

Enhancements:

* Renamed the nanoc configuration file from `config.yaml` to `nanoc.yaml`

Fixes:

* Updated references to old web site and old repository
* Made `require` errors mention Bundler if appropriate
* Fixed bug which caused pruner not to delete directories in some cases [Matthias Reitinger]
* Made `check` command exit with the proper exit status
* Added support for the `HTML_TOC` Redcarpet renderer
* Made `stale` check honor files excluded by the pruner

## 3.5 (2013-01-27)

Major changes:

* Added checks

Minor changes:

* Added `#include_rules` for modularising Rules files [Justin Hileman]
* Replaced FSSM with Listen [Takashi Uchibe]
* Made USR1 print stack trace (not on Windows)
* Added ability to configure autocompiler host/port in config.yaml [Stuart Montgomery]
* Added static data source
* Added `:rep_select` parameter to XML sitemap to allow filtering reps
* Removed use of bright/bold colors for compatibility with Solarized

Exensions:

* Added support for parameters in Less filter [Ruben Verborgh]
* Added support for icon and logo in Atom feed [Ruben Verborgh]

Fixes:

* Made syntax colorizer only use the first non-empty line when extracting the
  language comment
* Fixed XSL filter

## 3.4.3 (2012-12-09)

Improvements:

* Item reps are now accessible in a consistent way: in Rules and during
  compilation, they can be accessed using both `@rep` and `@item_rep`

Fixes:

* Made cleaning streams (stdout/stderr as used by nanoc) compatible with
  Ruby’s built-in Logger
* Made prune work when the output directory is a symlink
* Made Handlebars filter compatible with the latest version
* Made `show-data` command show more accurate dependencies [Stefan Bühler]
* Restored compatibility with Sass 3.2.2

## 3.4.2 (2012-11-01)

Fixes:

* Made passthrough rules be inserted in the right place [Gregory Pakosz]
* Fixed crashes in the progress indicator when compiling
* Made auto-pruning honor excluded files [Grégory Karékinian]
* Made lack of which/where not crash watch command

Improvements:

* Fixed constant reinitialization warnings [Damien Pollet]
* Made UTF-8 not be decomposed when outputting to a file from a non-UTF-8 terminal
* Made syntax colorizer wrap CodeRay output in required CodeRay divs
* Made fog delete after upload, not before [Go Maeda]
* Made requesting compiled content of binary item impossible

## 3.4.1 (2012-09-22)

Fixes:

* Fixed auto-pruning
* Made slim filter work with the capturing helper [Bil Bas]

Improvements:

* Made several speed improvements
* Added prune configuration to config.yaml
* Made nanoc check for presence of nanoc in Gemfile
* Made compile command not show identicals (use `--verbose` if you want them)
* Made `relativize_paths` filter recognise more paths to relativize [Arnau Siches]
* Fixed #passthrough for items without extensions [Justin Hileman]
* Added more IO/File proxy methods to cleaning streams

## 3.4 (2012-06-09)

* Improved error output and added crash log
* Renamed `debug` and `info` commands to `show-data` and `show-plugins`, respectively
* Added `show-rules` command (aka `explain`)

Extensions:

* Added `:yield` key for Mustache filter
* Added Handebars filter
* Added Pandoc filter
* Made the deployer use the `default` target if no target is specified
* Converted HTML/CSS/link validation tasks to commands
* Made link validator follow relative redirects

## 3.3.7 (2012-05-28)

* Added filename to YAML parser errors
* Fixed issue which caused extra dependencies to be generated
* Made timing information take filtering helper into account

## 3.3.6 (2012-04-27)

* Fixed issue with relative_link_to stripping HTML boilerplate

## 3.3.5 (2012-04-23)

* Fixed issue with relative_link_to not working properly

## 3.3.4 (2012-04-23)

* Fixed bug which caused the compilation stack to be empty
* Restored Ruby 1.8 compatibility

## 3.3.3 (2012-04-11)

* Fixed directed graph implementation on Rubinius
* Made capturing helper not remember content between runs
* Fixed Date#freeze issue on Ruby 1.8.x
* Made it possible to have any kind of object as parameters in the Rules file
* Fixed bug which caused changed routes not to cause a recompile

## 3.3.2 (2012-03-16)

* Removed bin/nanoc3 (use nanoc3 gem if you want it)
* Fixed wrong “no such snapshot” errors
* Made deployer default to rsync for backwards compatibility
* Fixed missing Nanoc::CLI in deployment tasks
* Fixed “unrecognised kind” deployer error

## 3.3.1 (2012-02-18)

* Fixed issue with long paths on Windows
* Fixed a few deployer crashes
* Added nanoc3.rb, nanoc3/tasks.rb, … for compatibility with older versions
* Made nanoc setup Bundler at startup [John Nishinaga]

## 3.3 (2012-02-12)

Base:

* Dropped the “3” suffix on nanoc3/Nanoc3
* Turned Rake tasks into proper nanoc commands
* Improved dependency tracking
* Added support for locals in filters and layouts

Extensions:

* Added support for deployment using Fog [Jack Chu]
* Added CoffeeScript filter [Riley Goodside]
* Added XSL filter [Arnau Siches]
* Added YUICompress filter [Matt Keveney]
* Added pygments.rb to supported syntax colorizers
* Allowed syntax colorizer to colorize outside `pre` elements [Kevin Lynagh]
* Added support for HTTPS link validation [Fabian Buch]
* Added support for (automatically) pruning stray output files [Justin Hileman]
* Added deploy command

## 3.2.4 (2012-01-09)

* Fixed bug which would cause some reps not to be compiled when invoking nanoc programmatically
* Made data source configuration location a bit more obvious
* Fixed watch command under Windows
* Made filesystem data source ignore UTF-8 BOM
* Improved compatibility of `colorize_syntax` filter with older libxml versions

## 3.2.3 (2011-10-31)

* Made syntax colorizer only strip trailing blank lines instead of all blanks
* Improved Ruby 1.9.x compatibility
* Made default rakefile require rubygems if necessary
* Made filename/content argument of `Nanoc3::Item#initialize` mandatory

## 3.2.2 (2011-09-04)

* Fixed command usage printing
* Made `relativize_paths` filter handle Windows network paths [Ruben Verborgh]
* Made watcher use correct configuration
* Allowed code blocks to start with a non-language shebang line

## 3.2.1 (2011-07-27)

* Made `@config` available in rules file
* Fixed `#readpartial` issue on JRuby [Matt Keveney]
* Fixed possible `@cache` name clash in memoization module
* Fixed options with required arguments (such as `--port` and `--host`)
* Fixed broken `#check_availability`
* Fixed error handling in watch command

## 3.2 (2011-07-24)

Base:

* Sped up nanoc quite a bit
* Added progress indicator for long-running filters
* Made all source data, such as item attributes, frozen during compilation
* Added --color option to force color on
* Cleaned up internals, deprecating several parts and/or marking them as private in the progress
* Allowed custom commands in commands/

Extensions:

* Added AsciiDoc filter
* Added Redcarpet filter [Peter Aronoff]
* Added Slim filter [Zaiste de Grengolada]
* Added Typogruby filter
* Added UglifyJS filter [Justin Hileman]
* Added `:items` parameter for the XML site map [Justin Hileman]
* Added support for params to ERB
* Added `:default_colorizer` parameter to the `:colorize_syntax` filter
* Allowed for passing arbitrary options to pygmentize [Matthias Vallentin]
* Exposed RedCloth parameters in the filter [Vincent Driessen]

## 3.1.9 (2011-06-30)

* Really fixed dependency generation between Sass partials this time
* Updated Less filter to 2.0
* Made `colorize_syntax` filter throw an error if pygmentize is not available

## 3.1.8 (2011-06-25)

* Made link validator accept https: URLs
* Fixed erroneous handling of layouts with names ending in index
* Fixed dependency generation between Sass partials
* Fixed errors related to thread requires
* Fixed crash while handling load errors
* Improved encoding handling while reading files

## 3.1.7 (2011-05-03)

* Restored compatibility with Sass 3.1

## 3.1.6 (2010-11-21)

* Fixed issues with incompatible encodings

## 3.1.5 (2010-08-24)

* Improved `#render` documentation
* Improved metadata section check so that e.g. raw diffs are handled properly
* Deprecated using `Nanoc3::Site#initialize` with a non-`"."` argument
* Added Ruby engine to version string
* Allowed the `created_at` and `updated_at` attributes used in the `Blogging` helper to be `Date` instances

## 3.1.4 (2010-07-25)

* Made INT and TERM signals always quit the CLI
* Allowed relative imports in LESS
* Made sure modification times are unchanged for identical recompiled items
* Improved link validator error handling
* Made pygmentize not output extra divs and pres
* Allowed colorizers to be specified using symbols instead of strings
* Added scss to the default list of text extensions

## 3.1.3 (2010-04-25)

* Removed annoying win32console warning [Eric Sunshine]
* Removed color codes when not writing to a terminal, or when writing to Windows’ console when win32console is not installed [Eric Sunshine]
* Added .xhtml and .xml to list of text extensions
* Improved support for relative Sass @imports [Chris Eppstein]

## 3.1.2 (2010-04-07)

* Fixed bug which could cause incorrect output when compilation of an item is delayed due to an unmet dependency

## 3.1.1 (2010-04-05)

* Sass `@import`s now work for files not managed by nanoc
* Rake tasks now have their Unicode description decomposed if necessary

## 3.1 (2010-04-03)

New:

* An `Item#rep_named(name)` function for quickly getting a certain rep
* An `Item#compiled_content` function for quickly getting compiled content
* An `Item#path` function for quickly getting the path of an item rep
* A new “+” wildcard in rule patterns that matches one or more characters
* A `view` command that starts a web server in the output directory
* A `debug` command that shows information about the items, reps and layouts
* A `kramdown` filter ([kramdown site](http://kramdown.gettalong.org/))
* A diff between the previously compiled content and the last compiled content is now written to `output.diff` if the `enable_output_diff` site configuration attribute is true
* Assigns, such as `@items`, `@layouts`, `@item`, … are accessible without `@`
* Support for binary items

Changed:

* New sites now come with a stylesheet item instead of a `style.css` file in the output directory
* The `deploy:rsync` task now use sensible default options
* The `deploy:rsync` task now accepts a config environment variable
* The `deploy:rsync` task now uses a lowercase `dry_run` environment variable
* The `maruku` filter now accepts parameters
* The `rainpress` filter now accepts parameters
* The `filesystem` data source is now known as `filesystem_verbose`
* Meta files and content files are now optional
* The `filesystem_compact` and `filesystem_combined` data sources have been merged into a new `filesystem_unified` data source
* The metadata section in `filesystem_unified` is now optional [Chris Eppstein]
* The `--server` autocompile option is now known as `--handler`
* Assigns in filters are now available as instance variables and methods
* The `#breadcrumbs_trail` function now allows missing parents
* The `sass` filter now properly handles `@import` dependencies

Deprecated:

* `Nanoc3::FileProxy`; use one of the filename attributes instead
* `ItemRep#content_at_snapshot`; use `#compiled_content` instead
* The `last_fm`, `delicious` and `twitter` data sources; fetch online content into a cache by a rake task and load data from this cache instead

## 3.0.9 (2010-02-24)

* Fixed 1.8.x parsing bug due to lack of parens which could cause “undefined method `to_iso8601_time` for #<String:0x…>” errors

## 3.0.8 (2010-02-24)

* `#atom_tag_for` now works with `base_url`s that contain a path [Eric Sunshine]
* Generated root URLs in `#atom_feed` now end with a slash [Eric Sunshine]
* Autocompiler now recognises requests to index files
* `Blogging` helper now allows `created_at` to be a Time instance

## 3.0.7 (2010-01-29)

* Fixed bug which could cause layout rules not be matched in order

## 3.0.6 (2010-01-17)

* Error checking in `filesystem_combined` has been improved [Brian Candler]
* Generated HTML files now have a default encoding of UTF-8
* Periods in identifiers for layouts now behave correctly
* The `relativize_paths` filter now correctly handles “/” [Eric Sunshine]

## 3.0.5 (2010-01-12)

* Restored pre-3.0.3 behaviour of periods in identifiers. By default, a file can have multiple extensions (e.g. `content/foo.html.erb` will have the identifier `/foo/`), but if `allow_periods_in_identifiers` in the site configuration is true, a file can have only one extension (e.g. `content/blog/stuff.entry.html` will have the identifier `/blog/stuff.entry/`).

## 3.0.4 (2010-01-07)

* Fixed a bug which would cause the `filesystem_compact` data source to incorrectly determine the content filename, leading to weird “Expected 1 content file but found 3” errors [Eric Sunshine]

## 3.0.3 (2010-01-06)

* The `Blogging` helper now properly handles item reps without paths
* The `relativize_paths` filter now only operates inside tags
* The autocompiler now handles escaped paths
* The `LinkTo` and `Tagging` helpers now output escaped HTML
* Fixed `played_at` attribute assignment in the `LastFM` data source for tracks playing now, and added a `now_playing` attribute [Nicky Peeters]
* The `filesystem_*` data sources can now handle dots in identifiers
* Required enumerator to make sure `#enum_with_index` always works
* `Array#stringify_keys` now properly recurses

## 3.0.2 (2009-11-07)

* Children-only identifier patterns no longer erroneously also match parent (e.g.` /foo/*/` no longer matches `/foo/`)
* The `create_site` command no longer uses those ugly HTML entities
* Install message now mentions the IRC channel

## 3.0.1 (2009-10-05)

* The proper exception is now raised when no matching compilation rules can be found
* The autocompile command no longer has a duplicate `--port` option
* The `#url_for` and `#feed_url` methods now check the presence of the `base_url` site configuration attribute
* Several outdated URLs are now up-to-date
* Error handling has been improved in general

## 3.0 (2009-08-14)

New:

* Multiple data sources
* Dependency tracking between items
* Filters can now optionally take arguments
* `#create_page` and `#create_layout` methods in data sources
* A new way to specify compilation/routing rules using a Rules file
* A `coderay` filter ([CodeRay site](http://coderay.rubychan.de/))
* A `filesystem_compact` data source which uses less directories

Changed:

* Pages and textual assets are now known as “items”

Removed:

* Support for drafts
* Support for binary assets
* Support for templates
* Everything that was deprecated in nanoc 2.x
* `save_*`, `move_*` and `delete_*` methods in data sources
* Processing instructions in metadata

## 2.2.2 (2009-05-18)

* Removed `relativize_paths` filter; use `relativize_paths_in_html` or `relativize_paths_in_css` instead
* Fixed bug which could cause nanoc to eat massive amounts of memory when an exception occurs
* Fixed bug which would cause nanoc to complain about the open file limit being reached when using a large amount of assets

## 2.2.1 (2009-04-08)

* Fixed bug which prevented `relative_path_to` from working
* Split `relativize_paths` filter into two filter: `relativize_paths_in_html` and `relativize_paths_in_css`
* Removed bundled mime-types library

## 2.2 (2009-04-06)

New:

* `--pages` and `--assets` compiler options
* `--no-color` command-line option
* `Filtering` helper
* `#relative_path_to` function in `LinkTo` helper
* `rainpress` filter ([Rainpress site](http://code.google.com/p/rainpress/))
* `relativize_paths` filter
* The current layout is now accessible through the `@layout` variable
* Much more informative stack traces when something goes wrong

Changed:

* The command-line option parser is now a lot more reliable
* `#atom_feed` now takes optional `:content_proc`, `:excerpt_proc` and `:articles` parameters
* The compile command show non-written items (those with `skip_output: true`)
* The compile command compiles everything by default
* Added `--only-outdated` option to compile only outdated pages

Removed:

* deprecated extension-based code

## 2.1.6 (2009-02-28)

* The `filesystem_combined` data source now supports empty metadata sections
* The `rdoc` filter now works for both RDoc 1.x and 2.x
* The autocompiler now serves a 500 when an exception occurs outside compilation
* The autocompiler no longer serves index files when the request path does not end with a slash
* The autocompiler now always serves asset content correctly

## 2.1.5 (2009-02-01)

* Added Ruby 1.9 compatibility
* The `filesystem` and `filesystem_combined` data sources now preserve custom extensions

## 2.1.4 (2008-11-15)

* Fixed an issue where the autocompiler in Windows would serve broken assets

## 2.1.3 (2008-09-27)

* The `haml` and `sass` filters now correctly take their options from assets
* The autocompiler now serves index files instead of 404s
* Layouts named “index” are now handled correctly
* The `filesystem_combined` data source now properly handles assets

## 2.1.2 (2008-09-08)

* The utocompiler now compiles assets as well
* The `sass` filter now takes options (just like the `haml` filter)
* Haml/Sass options are now taken from the page *rep* instead of the page

## 2.1.1 (2008-08-18)

* Fixed issue which would cause files not to be required in the right order

## 2.1 (2008-08-17)

This is only a short summary of all changes in 2.1. For details, see the
[nanoc web site](http://nanoc.stoneship.org/). Especially the blog and the
updated manual will be useful.

New:

* New `rdiscount` filter ([RDiscount site](http://github.com/rtomayko/rdiscount))
* New `maruku` filter ([Maruku site](https://github.com/bhollis/maruku/))
* New `erubis` filter ([Erubis site](http://www.kuwata-lab.com/erubis/))
* A better command-line frontend
* A new filesystem data source named `filesystem_combined`
* Routers, which decide where compiled pages should be written to
* Page/layout mtimes can now be retrieved through `page.mtime`/`layout.mtime`

Changed:

* Already compiled pages will no longer be re-compiled unless outdated
* Layout processors and filters have been merged
* Layouts no longer rely on file extensions to determine the layout processor
* Greatly improved source code documentation
* Greatly improved unit test suite

Removed:

* Several filters have been removed and replaced by newer filters:
	* `eruby`: use `erb` or `erubis` instead
	* `markdown`: use `bluecloth`, `rdiscount` or `maruku` instead
	* `textile`: use `redcloth` instead

## 2.0.4 (2008-05-04)

* Fixed `default.rb`’s `#html_escape`
* Updated Haml filter and layout processor so that @page, @pages and @config are now available as instance variables instead of local variables

## 2.0.3 (2008-03-25)

* The autocompiler now honors custom paths
* The autocompiler now attempts to serve pages with the most appropriate MIME type, instead of always serving everything as `text/html`

## 2.0.2 (2008-01-26)

* nanoc now requires Ruby 1.8.5 instead of 1.8.6

## 2.0.1 (2008-01-21)

* Fixed a “too many open files” error that could appear during (auto)compiling

## 2.0 (2007-12-25)

New:

* Support for custom layout processors
* Support for custom data sources
* Database data source
* An auto-compiler
* Pages have `parent` and `children`

Changed:

* The source has been restructured and cleaned up a great deal
* Filters are defined in a different way now
* The `eruby` filter now uses ERB instead of Erubis

Removed:

* The `filters` property; use `filters_pre` instead
* Support for Liquid

## 1.6.2 (2007-10-23)

* Fixed an issue which prevented the content capturing plugin from working

## 1.6.1 (2007-10-14)

* Removed a stray debug message

## 1.6 (2007-10-13)

* Added support for post-layout filters
* Added support for getting a File object for the page, so you can now e.g. easily get the modification time for a given page (`@page.file.mtime`)
* Cleaned up the source code a lot
* Removed deprecated asset-copying functionality

## 1.5 (2007-09-10)

* Added support for custom filters
* Improved Liquid support -- Liquid is now a first-class nanoc citizen
* Deprecated assets -- use something like rsync instead
* Added `eruby_engine` option, which can be `erb` or `erubis`

## 1.4 (2007-07-06)

* nanoc now supports ERB (as well as Erubis); Erubis no longer is a dependency
* `meta.yaml` can now have `haml_options` property, which is passed to Haml
* Pages can now have a `filename` property, which defaults to `index` [Dennis Sutch]
* Pages now know in what order they should be compiled, eliminating the need for custom page ordering [Dennis Sutch]

## 1.3.1 (2007-06-30)

* The contents of the `assets` directory are now copied into the output directory specified in `config.yaml`

## 1.3 (2007-06-24)

* The `@pages` array now also contains uncompiled pages
* Pages with `skip_output` set to true will not be outputted
* Added new filters
	* Textile/RedCloth
	* Sass
* nanoc now warns before overwriting in `create_site`, `create_page` and `create_template` (but not in compile)

## 1.2 (2007-06-05)

* Sites now have an `assets` directory, whose contents are copied to the `output` directory when compiling [Stanley Rost]
* Added support for non-eRuby layouts (Markaby, Haml, Liquid, …)
* Added more filters (Markaby, Haml, Liquid, RDoc [Dmitry Bilunov])
* Improved error reporting
* Accessing page attributes using instance variables, and not through `@page`, is no longer possible
* Page attributes can now be accessed using dot notation, i.e. `@page.title` as well as `@page[:title]`

## 1.1.3 (2007-05-18)

* Fixed bug which would cause layoutless pages to be outputted incorrectly

## 1.1.2 (2007-05-17)

* Backup files (files ending with a “~”) are now ignored
* Fixed bug which would cause subpages not to be generated correctly

## 1.1 (2007-05-08)

* Added support for nested layouts
* Added coloured logging
* `@page` now hold the page that is currently being processed
* Index files are now called “content” files and are now named after the directory they are in [Colin Barrett]
* It is now possible to access `@page` in the page’s content file

## 1.0.1 (2007-05-05)

* Fixed a bug which would cause a “no such template” error to be displayed when the template existed but compiling it would raise an exception
* Fixed bug which would cause pages not to be sorted by order before compiling

## 1.0 (2007-05-03)

* Initial release
