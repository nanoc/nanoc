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

    # TODO: Replace rule_memory_calculator with { rep => rule_memory }
    def initialize(reps, rule_memory_calculator, site)
      @reps = reps
      @rule_memory_calculator = rule_memory_calculator
      @site = site
    end

    def run
      paths_to_reps = {}
      @reps.each do |rep|
        mem = @rule_memory_calculator[rep]
        mem.snapshot_actions.each do |snapshot_action|
          route_rep(rep, snapshot_action, paths_to_reps)
        end
      end
    end

    def route_rep(rep, snapshot_action, paths_to_reps)
      basic_path = snapshot_action.path
      return if basic_path.nil?

      # Check for duplicate paths
      if paths_to_reps.key?(basic_path)
        raise IdenticalRoutesError.new(basic_path, paths_to_reps[basic_path], rep)
      else
        paths_to_reps[basic_path] = rep
      end

      rep.raw_paths[snapshot_action.snapshot_name] = @site.config[:output_dir] + basic_path
      rep.paths[snapshot_action.snapshot_name] = strip_index_filename(basic_path)
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
