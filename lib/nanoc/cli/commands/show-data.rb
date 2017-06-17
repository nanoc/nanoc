# frozen_string_literal: true

usage 'show-data'
aliases :debug
summary 'show data in this site'
description <<~EOS
  Show information about all items, item representations and layouts in the
  current site, along with dependency information.
EOS

module Nanoc::CLI::Commands
  class ShowData < ::Nanoc::CLI::CommandRunner
    def run
      load_site(preprocess: true)

      # Get data
      items   = site.items
      layouts = site.layouts

      # Get dependency tracker
      compiler = site.compiler
      compiler.load_stores
      dependency_store = compiler.dependency_store

      # Build reps
      compiler.build_reps

      # Print data
      print_item_dependencies(items, dependency_store)
      print_item_rep_paths(items)
      print_item_rep_outdatedness(items, compiler)
      print_layouts(layouts, compiler)
    end

    protected

    def sorted_with_prev(objects)
      prev = nil
      objects.sort_by(&:identifier).each do |object|
        yield(object, prev)
        prev = object
      end
    end

    def sorted_reps_with_prev(items)
      prev = nil
      items.sort_by(&:identifier).each do |item|
        site.compiler.reps[item].sort_by { |r| r.name.to_s }.each do |rep|
          yield(rep, prev)
          prev = rep
        end
      end
    end

    def print_header(title)
      header = '=' * 78
      header[3..(title.length + 5)] = " #{title} "

      puts
      puts header
      puts
    end

    def print_item_dependencies(items, dependency_store)
      print_header('Item dependencies')

      puts 'Legend:'
      puts '  r = dependency on raw content'
      puts '  a = dependency on attributes'
      puts '  c = dependency on compiled content'
      puts '  p = dependency on the path'
      puts

      sorted_with_prev(items) do |item, prev|
        puts if prev
        puts "item #{item.identifier} depends on:"
        dependencies =
          dependency_store
          .dependencies_causing_outdatedness_of(item)
          .sort_by { |dep| dep.from ? dep.from.identifier : '' }
        dependencies.each do |dep|
          pred = dep.from

          type =
            case pred
            when Nanoc::Int::Layout
              'layout'
            when Nanoc::Int::Item
              'item'
            else
              raise Nanoc::Int::Errors::InternalInconsistency, "unexpected pred type #{pred}"
            end

          props = String.new
          props << (dep.props.raw_content? ? 'r' : '_')
          props << (dep.props.attributes? ? 'a' : '_')
          props << (dep.props.compiled_content? ? 'c' : '_')
          props << (dep.props.path? ? 'p' : '_')

          if pred
            puts "  [ #{format '%6s', type} ] (#{props}) #{pred.identifier}"
          else
            puts '  ( removed item )'
          end
        end
        puts '  (nothing)' if dependencies.empty?
      end
    end

    def print_item_rep_paths(items)
      print_header('Item representation paths')

      sorted_reps_with_prev(items) do |rep, prev|
        puts if prev
        puts "item #{rep.item.identifier}, rep #{rep.name}:"
        if rep.raw_paths.empty?
          puts '  (not written)'
        end
        length = rep.raw_paths.keys.map { |s| s.to_s.length }.max
        rep.raw_paths.each do |snapshot_name, raw_paths|
          raw_paths.each do |raw_path|
            puts format("  [ %-#{length}s ] %s", snapshot_name, raw_path)
          end
        end
      end
    end

    def print_item_rep_outdatedness(items, compiler)
      print_header('Item representation outdatedness')

      sorted_reps_with_prev(items) do |rep, prev|
        puts if prev
        puts "item #{rep.item.identifier}, rep #{rep.name}:"
        print_outdatedness_reasons_for(rep, compiler)
      end
    end

    def print_layouts(layouts, compiler)
      print_header('Layouts')

      sorted_with_prev(layouts) do |layout, prev|
        puts if prev
        puts "layout #{layout.identifier}:"
        print_outdatedness_reasons_for(layout, compiler)
      end
    end

    def print_outdatedness_reasons_for(obj, compiler)
      compiler.calculate_checksums
      outdatedness_checker = compiler.create_outdatedness_checker
      reasons = outdatedness_checker.outdatedness_reasons_for(obj)
      if reasons.any?
        puts '  is outdated:'
        reasons.each do |reason|
          puts "    - #{reason.message}"
        end
      else
        puts '  is not outdated'
      end
    end
  end
end

runner Nanoc::CLI::Commands::ShowData
