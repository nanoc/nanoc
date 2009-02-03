require 'rake/clean'

CLEAN.include([
  'coverage',
  'rdoc',
  'tmp',
  File.join('test', 'fixtures', '*', 'output', '*'),
  File.join('test', 'fixtures', '*', 'tmp')
])

CLOBBER.include([ 'pkg' ])
