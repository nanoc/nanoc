# frozen_string_literal: true

usage 'live'
summary 'auto-recompile and serve'
description <<~EOS
  Starts the live recompiler along with the static web server. Unless specified,
  the web server will run on port 3000 and listen on all IP addresses. Running
  this static web server requires `adsf` (not `asdf`!).
EOS

required :H, :handler, 'specify the handler to use (webrick/mongrel/...)'
required :o, :host,    'specify the host to listen on (default: 127.0.0.1)', default: '127.0.0.1'
required :p, :port,    'specify the port to listen on (default: 3000)', transform: Nanoc::CLI::Transform::Port, default: 3000
no_params

runner Nanoc::Live::CommandRunners::Live
