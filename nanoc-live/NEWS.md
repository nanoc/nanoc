# Release notes for nanoc-live

## 1.1.0 (2024-06-26)

Enhancements:

- Added `--focus` option to the `compile` and `live` commands (#1707)

Fixes:

- Fixed wrong documentation regarding listening IP addresses (#1584) [Jan M. Faber]

Changes:

- Dropped support for Ruby 3.0 (EOL) (#1704)

## 1.0.0 (2021-02-20)

Idential to 1.0.0b8.

## 1.0.0b8 (2021-01-16)

Fixes:

- Fixed issue which could cause nanoc-live to keep running and use 100% CPU (#1538)

## 1.0.0b7 (2021-01-01)

Enhancements:

- Added support for Ruby 3.x

## 1.0.0b6 (2020-03-07)

Fixes:

- Restored compatibility with Nanoc 4.11.14.

## 1.0.0b5 (2019-11-16)

Fixes:

- Restored compatibility with Nanoc 4.11.13.

## 1.0.0b4 (2019-04-30)

Fixes:

- Restored compatibility with most recent version of Nanoc.

## 1.0.0b3 (2018-08-31)

Fixes:

- Fixed issue which required all command-line options to be specified

## 1.0.0b2 (2018-06-10)

Fixes:

- Fixed issues that could cause nanoc-live to keep running in the background, using more and more memory and CPU

## 1.0.0b1 (2018-01-07)

Changes:

- Removed `--live-reload` (always enabled) (#1291)

## 1.0.0a2 (2017-12-09)

Fixes:

- Added missing dependency on `adsf-live`
- Fixed errors not being printed (#1271)

## 1.0.0a1 (2017-12-03)

Initial release.
