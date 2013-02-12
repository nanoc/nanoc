# encoding: utf-8

usage       'shell'
summary     'open a shell on the nanoc environment'
aliases     'console'
description <<-EOS
Open an IRB shell on a context that contains @items, @layouts, @config and @site.
EOS

module Nanoc::CLI::Commands

  class Shell < ::Nanoc::CLI::CommandRunner

    def run
      require 'pry'

      self.require_site

      Nanoc::Context.new(env).pry
    end

  protected

    def env
      {
        :site    => self.site,
        :items   => self.site.items,
        :layouts => self.site.layouts,
        :config  => self.site.config
      }
    end

  end

end

runner Nanoc::CLI::Commands::Shell
