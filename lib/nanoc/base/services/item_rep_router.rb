module Nanoc::Int
  # Assigns paths to reps.
  #
  # @api private
  class ItemRepRouter
    class IdenticalRoutesError < ::Nanoc::Error
      def initialize(output_path, rep_a, rep_b)
        super("The item representations #{rep_a.inspect} and #{rep_b.inspect} are both routed to #{output_path}.")
      end
    end

    def initialize(reps, rules_collection, site)
      @reps = reps
      @rules_collection = rules_collection
      @site = site
    end

    def run
      paths_to_reps = {}
      @reps.each do |rep|
        rules = @rules_collection.routing_rules_for(rep)
        raise Nanoc::Int::Errors::NoMatchingRoutingRuleFound.new(rep) if rules[:last].nil?

        rules.each_pair do |snapshot, rule|
          route_rep(rep, snapshot, rule, paths_to_reps)
        end
      end
    end

    def route_rep(rep, snapshot, rule, paths_to_reps)
      basic_path = basic_path_for(rep, rule)
      return if basic_path.nil?

      # Check for duplicate paths
      if paths_to_reps.key?(basic_path)
        raise IdenticalRoutesError.new(basic_path, paths_to_reps[basic_path], rep)
      else
        paths_to_reps[basic_path] = rep
      end

      rep.raw_paths[snapshot] = @site.config[:output_dir] + basic_path
      rep.paths[snapshot] = strip_index_filename(basic_path)
    end

    def basic_path_for(rep, rule)
      basic_path = rule.apply_to(rep, executor: nil, site: @site, view_context: nil)

      if basic_path && basic_path !~ %r{^/}
        raise "The path returned for the #{rep.inspect} item representation, “#{basic_path}”, does not start with a slash. Please ensure that all routing rules return a path that starts with a slash."
      end

      basic_path
    end

    def strip_index_filename(basic_path)
      @site.config[:index_filenames].each do |index_filename|
        rep_path_ending = basic_path[-index_filename.length..-1]
        next unless rep_path_ending == index_filename

        return basic_path[0..-index_filename.length - 1]
      end

      basic_path
    end
  end
end
