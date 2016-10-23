usage 'query'
summary 'evaluate an expression in the Nanoc environment'
description "
Evaluate and print the results of the given expression in a context that contains @items, @layouts, and @config.
"

# TODO: only when Nanoc::Feature.enabled?(Nanoc::Feature::QUERY_COMMAND)
# TODO: extract env creation

module Nanoc::CLI::Commands
  class Query < ::Nanoc::CLI::CommandRunner
    def run
      load_site
      ctx = Nanoc::Int::Context.new(env)
      puts fmt(eval(arguments.join(' '), ctx.get_binding))
    end

    protected

    def fmt(thing)
      case res
      when String
        res
      when Array
        res.map(&:to_s).join("\n")
      else
        res.inspect
      end
    end

    def env
      self.class.env_for_site(site)
    end

    def self.env_for_site(site)
      {
        items: Nanoc::ItemCollectionWithRepsView.new(site.items, nil),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, nil),
        config: Nanoc::ConfigView.new(site.config, nil),
      }
    end
  end
end

runner Nanoc::CLI::Commands::Query
