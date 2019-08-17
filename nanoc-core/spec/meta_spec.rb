# frozen_string_literal: true

describe 'meta', chdir: false do
  example do
    regular_files = Dir['lib/nanoc/core/**/*.rb']
    regular_file_base_names = regular_files.map { |fn| fn.gsub(/^lib\/nanoc\/core\/|\.rb$/, '') }

    spec_files = Dir['spec/nanoc/core/**/*_spec.rb']
    spec_file_base_names = spec_files.map { |fn| fn.gsub(/^spec\/nanoc\/core\/|_spec\.rb$/, '') }

    # TODO: don’t ignore anything
    ignored = %w[
      action_provider
      action_sequence_store
      checksum_collection
      contracts_support
      dependency
      error
      errors
      item_collection
      item_rep_repo
      layout_collection
      outdatedness_reasons
      outdatedness_rule
      processing_actions
      snapshot_def
      version
    ]

    expect(regular_file_base_names - ignored).to match_array(spec_file_base_names)
  end
end
