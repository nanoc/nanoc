# frozen_string_literal: true

module Nanoc::Int
  # Assigns paths to reps.
  #
  # @api private
  class ItemRepRouter
    include Nanoc::Int::ContractsSupport

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
      action_sequences = {}
      assigned_paths = {}
      @reps.each do |rep|
        # Sigh. We route reps twice, because the first time, the paths might not have converged
        # yet. This isn’t ideal, but it’s the only way to work around the divergence issues that
        # I can think of. For details, see
        # https://github.com/nanoc/nanoc/pull/1085#issuecomment-280628426.

        @action_provider.action_sequence_for(rep).paths.each do |(snapshot_names, paths)|
          route_rep(rep, paths, snapshot_names, {})
        end

        seq = @action_provider.action_sequence_for(rep)
        action_sequences[rep] = seq
        seq.paths.each do |(snapshot_names, paths)|
          route_rep(rep, paths, snapshot_names, assigned_paths)
        end

        # TODO: verify that paths converge
      end

      action_sequences
    end

    contract Nanoc::Int::ItemRep, C::IterOf[String], C::IterOf[Symbol], C::HashOf[String => Nanoc::Int::ItemRep] => C::Any
    def route_rep(rep, paths, snapshot_names, assigned_paths)
      # Encode
      paths = paths.map { |path| path.encode('UTF-8') }

      # Validate format
      paths.each do |path|
        unless path.start_with?('/')
          raise RouteWithoutSlashError.new(path, rep)
        end
      end

      # Validate uniqueness
      paths.each do |path|
        if assigned_paths.include?(path)
          # TODO: Include snapshot names in error message
          raise IdenticalRoutesError.new(path, assigned_paths[path], rep)
        end
      end
      paths.each do |path|
        assigned_paths[path] = rep
      end

      # Assign
      snapshot_names.each do |snapshot_name|
        rep.raw_paths[snapshot_name] = paths.map { |path| @site.config[:output_dir] + path }
        rep.paths[snapshot_name] = paths.map { |path| strip_index_filename(path) }
      end
    end

    contract String => String
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
