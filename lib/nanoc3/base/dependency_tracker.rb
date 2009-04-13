require 'pstore'

module Nanoc3

  # Nanoc3::DependencyTracker records the dependencies between items and their
  # representations. It does so by keeping track of "visit_started" and
  # "visit_ended" events.
  class DependencyTracker

    # Name of the file that contains the dependency data.
    DEPENDENCIES_FILE_NAME = 'dependencies.dat'

    # Creates a new dependency tracker witih an empty dependency graph.
    def initialize
      @dependency_graph = {}
    end

    # Starts the dependency tracker by having it listen to visit started/ended
    # events, and extract dependency information from the order of events.
    def start
      # Initialize
      @stack = []

      # Register start of visits
      Nanoc3::NotificationCenter.on(:visit_started, :dependency_tracker) do |obj|
        @stack.push(obj_to_id(obj))
      end

      # Register end of visits
      Nanoc3::NotificationCenter.on(:visit_ended, :dependency_tracker) do |obj|
        add_dependency(@stack[-2], @stack[-1]) if @stack.size >= 2
        @stack.pop
      end
    end

    # Stops the dependency tracker. Visit started/ended events will no longer
    # be recorded.
    def stop
      # Unregister
      Nanoc3::NotificationCenter.remove(:visit_started, :dependency_tracker)
      Nanoc3::NotificationCenter.remove(:visit_ended,   :dependency_tracker)
    end

    # Loads the dependency graph from its store.
    def load_state
      return unless File.file?('tmp/' + DEPENDENCIES_FILE_NAME)

      # Load dependencies
      store = PStore.new('tmp/' + DEPENDENCIES_FILE_NAME)
      store.transaction do
        @dependency_graph = store[:dependencies]
      end
    end

    # Stores the dependency graph in its store.
    def store_state
      # Create tmp dir
      FileUtils.mkdir_p('tmp')

      # Store dependencies
      store = PStore.new('tmp/' + DEPENDENCIES_FILE_NAME)
      store.transaction do
        store[:dependencies] = @dependency_graph
      end
    end

    # Marks all item representations that are (directly or indirectly)
    # affected by an outdated rep as outdated.
    def mark_outdated_dependencies(reps)
      # Treat everything as outdated when no dependency data is available
      if @dependency_graph == {}
        reps.each { |rep| rep.force_outdated = true }
        return
      end

      # Loop through all reps, repeatedly, until all outdated reps have been
      # marked as such
      anything_changed = true
      while anything_changed do
        anything_changed = false
        reps.each do |rep|
          # Skip outdated reps
          next unless rep.outdated?

          # Mark explicitly as outdated
          anything_changed = true if !rep.force_outdated
          rep.force_outdated = true

          # Get dependencies
          dependencies_raw = @dependency_graph[obj_to_id(rep)]
          dependencies = dependencies_raw.map do |dependency|
            reps.find do |rep|
              rep.item.identifier == dependency[1] && :item == dependency[0]
            end
          end

          # Mark dependencies as outdated
          dependencies.each do |d|
            anything_changed = true if !d.force_outdated
            d.force_outdated = true
          end
        end
      end
    end

  private

    # Returns an unique identifier for the given object. This identifier is stored in the dependency graph file.
    def obj_to_id(obj)
      if obj.is_a?(Nanoc3::ItemRep)
        [ :item, obj.item.identifier ]
      elsif obj.is_a?(Nanoc3::Item)
        [ :item, obj.identifier ]
      end
    end

    # Adds a dependency between +from+ and +to+. When +to+ changes, +from+
    # will need to be recompiled, i.e. +from+ depends on +to+.
    def add_dependency(from, to)
      # Initialize list of dependencies if necessary
      @dependency_graph[to] ||= []

      # Skip if equal
      return if from == to

      # Skip if already included
      return if @dependency_graph[to].include?(from)

      # Add dependency
      @dependency_graph[to] << from
    end

  end

end
