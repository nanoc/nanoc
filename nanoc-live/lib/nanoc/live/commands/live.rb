# frozen_string_literal: true

usage 'live'
summary 'auto-recompile and serve'
description <<~EOS
  Starts the live recompiler along with the static web server. Unless specified,
  the web server will run on port 3000 and listen on 127.0.0.1. Running this
  static web server requires `adsf` (not `asdf`!).
EOS

option :H,  :handler, 'specify the handler to use (webrick/puma/...)', argument: :required
option :o,  :host,    'specify the host to listen on', default: '127.0.0.1', argument: :required
option :p,  :port,    'specify the port to listen on', transform: Nanoc::CLI::Transform::Port, default: 3000, argument: :required
option nil, :focus,   'compile only items matching the given pattern', argument: :required, multiple: true
no_params

runner Nanoc::Live::CommandRunners::Live
