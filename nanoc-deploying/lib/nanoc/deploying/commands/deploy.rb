# frozen_string_literal: true

usage 'deploy [target] [options]'
summary 'deploy the compiled site'
description "
Deploys the compiled site. The compiled site contents in the output directory will be uploaded to the destination, which is specified using the `--target` option.
"

option :t, :target,         'specify the location to deploy to (default: `default`)', argument: :required
flag :C, :'no-check',       'do not run the issue checks marked for deployment'
flag :L, :list,             'list available locations to deploy to'
flag :D, :'list-deployers', 'list available deployers'
option :n, :'dry-run',      'show what would be deployed'

runner Nanoc::Deploying::CommandRunners::Deploy
