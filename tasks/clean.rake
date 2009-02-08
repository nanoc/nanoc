require 'rake/clean'

CLEAN.include([
  'coverage',
  'rdoc',
  'tmp'
])

CLOBBER.include([ 'pkg' ])
