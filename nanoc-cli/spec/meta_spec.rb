# frozen_string_literal: true

describe 'meta', chdir: false do
  it 'is covered by specs' do
    regular_files = Dir['lib/nanoc/cli/**/*.rb']
    regular_file_base_names = regular_files.map { |fn| fn.gsub(/^lib\/nanoc\/cli\/|\.rb$/, '').tr('-', '_') }

    spec_files = Dir['spec/nanoc/cli/**/*_spec.rb']
    spec_file_base_names = spec_files.map { |fn| fn.gsub(/^spec\/nanoc\/cli\/|_spec\.rb$/, '').tr('-', '_') }

    # TODO: don’t ignore anything
    ignored_regular_file_base_names = %w[
      stream_cleaners/abstract
      stream_cleaners/ansi_colors
      ansi_string_colorizer
      commands/create_site
      commands/nanoc
      commands/prune
      compile_listeners/aggregate
      logger
      transform
    ]

    ignored_spec_file_base_names = %w[]

    effective_regular_file_base_names =
      regular_file_base_names - ignored_regular_file_base_names

    effective_spec_file_base_names =
      spec_file_base_names - ignored_spec_file_base_names

    expect(effective_regular_file_base_names)
      .to match_array(effective_spec_file_base_names)
  end
end
