# encoding: utf-8

usage       'shell'
summary     'open a shell on the nanoc environment'
aliases     'console'
description "
Open an IRB shell on a context that contains @items, @layouts, @config and @site.
"

module Nanoc::CLI::Commands

  class Shell < ::Nanoc::CLI::CommandRunner

    def run
      require 'pry'

      require_site

      Nanoc::Context.new(env).pry
    end

  protected

    def env
      {
        :site    => site,
        :items   => site.items,
        :layouts => site.layouts,
        :config  => site.config
      }
    end

  end

end

runner Nanoc::CLI::Commands::Shell
