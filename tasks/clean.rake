require 'rake/clean'

CLEAN.include([
  'coverage',
  'doc',
  'tmp'
])

CLOBBER.include([ 'pkg' ])
