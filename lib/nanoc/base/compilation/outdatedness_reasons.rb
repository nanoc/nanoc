# encoding: utf-8

module Nanoc

  # Module that contains all outdatedness reasons.
  module OutdatednessReasons

    # A generic outdatedness reason. An outdatedness reason is basically a
    # descriptive message that explains why a given object is outdated.
    class Generic

      # @return [String] A descriptive message for this outdatedness reason
      attr_reader :message

      # @param [String] message The descriptive message for this outdatedness
      #   reason
      def initialize(message)
        @message = message
      end

    end

    CodeSnippetsModified = Generic.new(
      'The code snippets have been modified since the last time the site was compiled.')

    ConfigurationModified = Generic.new(
      'The site configuration has been modified since the last time the site was compiled.')

    DependenciesOutdated = Generic.new(
      'This item uses content or attributes that have changed since the last time the site was compiled.')

    NotEnoughData = Generic.new(
      'Not enough data is present to correctly determine whether the item is outdated.')

    NotWritten = Generic.new(
      'This item representation has not yet been written to the output directory (but it does have a path).')

    RulesModified = Generic.new(
      'The rules file has been modified since the last time the site was compiled.')

    SourceModified = Generic.new(
      'The source file of this item has been modified since the last time the site was compiled.')

  end

end
