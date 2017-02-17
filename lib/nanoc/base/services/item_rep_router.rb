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

    class RouteWithoutSlashError < ::Nanoc::Error
      def initialize(output_path, rep)
        super("The item representation #{rep.inspect} is routed to #{output_path}, which does not start with a slash, as required.")
      end
    end

    def initialize(reps, action_provider, site)
      @reps = reps
      @action_provider = action_provider
      @site = site
    end

    def run
      paths_to_reps = {}
      @reps.each do |rep|
        @action_provider.paths_for(rep).each do |(snapshot_name, path)|
          route_rep(rep, path, snapshot_name, paths_to_reps)
        end
      end
    end

    def route_rep(rep, path, snapshot_name, paths_to_reps)
      basic_path = path
      return if basic_path.nil?
      basic_path = basic_path.encode('UTF-8')

      unless basic_path.start_with?('/')
        raise RouteWithoutSlashError.new(basic_path, rep)
      end

      # Check for duplicate paths
      if paths_to_reps.key?(basic_path)
        raise IdenticalRoutesError.new(basic_path, paths_to_reps[basic_path], rep)
      else
        paths_to_reps[basic_path] = rep
      end

      rep.raw_paths[snapshot_name] = @site.config[:output_dir] + basic_path
      rep.paths[snapshot_name] = strip_index_filename(basic_path)
    end

    def strip_index_filename(basic_path)
      @site.config[:index_filenames].each do |index_filename|
        slashed_index_filename = '/' + index_filename
        if basic_path.end_with?(slashed_index_filename)
          return basic_path[0..-index_filename.length - 1]
        end
      end

      basic_path
    end
  end
end
