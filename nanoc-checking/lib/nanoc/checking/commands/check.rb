# frozen_string_literal: true

usage 'check [options] [names]'
summary 'run issue checks'
description "
Run issue checks on the current site. If the `--all` option is passed, all available issue checks will be run. By default, the issue checks marked for deployment will be run.
"

flag :a, :all,    'run all checks'
flag :L, :list,   'list all checks'
flag :d, :deploy, '(deprecated)'

runner Nanoc::Checking::CommandRunners::Check
