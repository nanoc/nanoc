# frozen_string_literal: true

module Nanoc::Deploying::Deployers
  # A deployer that deploys a site using rsync.
  #
  # The configuration has should include a `:dst` value, a string containing
  # the destination to where rsync should upload its data. It will likely be
  # in `host:path` format. It should not end with a slash. For example,
  # `"example.com:/var/www/sites/mysite/html"`.
  #
  # @example A deployment configuration with public and staging configurations
  #
  #   deploy:
  #     public:
  #       kind: rsync
  #       dst: "ectype:sites/stoneship/public"
  #     staging:
  #       kind: rsync
  #       dst: "ectype:sites/stoneship-staging/public"
  #       options: [ "-glpPrtvz" ]
  #
  # @api private
  class Rsync < ::Nanoc::Deploying::Deployer
    identifier :rsync

    # Default rsync options
    DEFAULT_OPTIONS = [
      '--group',
      '--links',
      '--perms',
      '--partial',
      '--progress',
      '--recursive',
      '--times',
      '--verbose',
      '--compress',
      '--exclude=".hg"',
      '--exclude=".svn"',
      '--exclude=".git"',
    ].freeze

    # @see Nanoc::Deploying::Deployer#run
    def run
      # Get params
      src = source_path + '/'
      dst = config[:dst]
      options = config[:options] || DEFAULT_OPTIONS

      # Validate
      raise 'No dst found in deployment configuration' if dst.nil?
      raise 'dst requires no trailing slash' if dst[-1, 1] == '/'

      # Run
      if dry_run
        warn 'Performing a dry-run; no actions will actually be performed'
        run_shell_cmd(['echo', 'rsync', options, src, dst].flatten)
      else
        run_shell_cmd(['rsync', options, src, dst].flatten)
      end
    end

    private

    def run_shell_cmd(cmd)
      piper = Nanoc::Extra::Piper.new(stdout: $stdout, stderr: $stderr)
      piper.run(cmd, nil)
    end
  end
end
