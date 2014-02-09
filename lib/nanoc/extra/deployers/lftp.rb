# encoding: utf-8

# Inspired by https://github.com/nanoc/nanoc/blob/9b58936e31c00aeb7589b6abb88cf4f2ed73eb5b/lib/nanoc/extra/deployers/rsync.rb

module Nanoc::Extra::Deployers

  # A deployer that deploys a site using lftp - http://lftp.yar.ru/.
  #
  # The configuration has to include a `dst` value, a string containing
  # the destination to where lftp should upload its data. It has to be
  # in `scheme://user:password@host:port/path` format. It must not end with a slash. For example,
  # `"sftp://user@example.com/var/www/sites/mysite/html"`.
  #
  # @example A deployment configuration with public and staging configurations
  #
  #   deploy:
  #     public:
  #       kind: lftp
  #       dst: "ftp://user@example.com/sites/stoneship/public"
  #
  class Lftp < ::Nanoc::Extra::Deployer

    # Default lftp options
    DEFAULT_OPTIONS = []

    # @see Nanoc::Extra::Deployer#run
    def run
      require 'systemu'         # I'm not happy with systemu but try to follow the way rsync goes.

      # Get params
      src = source_path + '/'
      dst = config[:dst]
      options = config.fetch(:options, DEFAULT_OPTIONS)

      # Validate
      raise 'No dst found in deployment configuration' if dst.nil?
      # separate host (incl. scheme + optional port) and path.
      # Don't URI::parse because sftp is unknown and yields a different 'path' value than ftp -
      # look at URI::parse('ftp://a/b').path vs. URI::parse('sftp://a/b').path
      uri_regexp = /^([^\/]+:\/\/[^\/]+)(.*)$/
      match = uri_regexp.match dst
      raise "dst in deployment configuration must match regexp #{uri_regexp.source}" if match.nil?
      scheme_host_port = match[1]
      path = match[2]
      raise 'dst allows no trailing slash' if path[-1, 1] == '/'

      lftp_cmd = "-e 'mirror --reverse #{options.flatten.join(' ')} #{src} #{path} ; quit'"
      # looks like 'systemu' below chokes on arrays for input
      # todo: needs proper escaping.
      # This way we're insecure in terms of shell escaping, but at least it works under friendly conditions.
      cmd = [ 'lftp', lftp_cmd, scheme_host_port ].join(' ')

      # Run
      if dry_run
        warn 'Performing a dry-run; no actions will actually be performed'
        $stdout.puts cmd
      else
        run_shell_cmd cmd
      end
    end

  private

    # Runs the given shell command. It will raise an error if execution fails
    # (results in a nonzero exit code).
    def run_shell_cmd(args)
      status = systemu(args, 'stdout' => $stdout, 'stderr' => $stderr)
      raise "command exited with a nonzero status code #{status.exitstatus} (command: #{args})" if !status.success?
    end

  end

end
