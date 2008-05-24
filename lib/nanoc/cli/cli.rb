# Define CLI namespace
module Nanoc::CLI ; end

# Load extensions
Nanoc.load('cli', 'ext.rb')
Nanoc.load('cli', 'option_parser.rb')

# Load logger
Nanoc.load('cli', 'logger.rb')

# Load commands
Nanoc.load('cli', 'command.rb')
Nanoc.load('cli', 'commands', '*.rb')

# Load base
Nanoc.load('cli', 'base.rb')
