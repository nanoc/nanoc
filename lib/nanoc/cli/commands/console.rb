# encoding: utf-8

usage       'console'
summary     'open a console on the nanoc environment'
description <<-EOS
Open an IRB console on a context that contains @items, @layouts, and @config.
EOS

module Nanoc::CLI::Commands

  class Console < ::Nanoc::CLI::CommandRunner

    def run
      require 'pry'

      self.require_site

      Nanoc::Context.new(env).pry
    end

  protected

    def env
      {
        :items   => self.site.items,
        :layouts => self.site.layouts,
        :config  => self.site.config
      }
    end

  end

end

runner Nanoc::CLI::Commands::Console
