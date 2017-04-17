module Nanoc::Int::Compiler::Stages
end

require_relative 'stages/calculate_checksums'
require_relative 'stages/cleanup'
require_relative 'stages/compile_reps'
require_relative 'stages/determine_outdatedness'
require_relative 'stages/prune'
require_relative 'stages/preprocess'
require_relative 'stages/load_stores'
require_relative 'stages/forget_outdated_dependencies'
require_relative 'stages/store_pre_compilation_state'
require_relative 'stages/store_post_compilation_state'
require_relative 'stages/postprocess'
require_relative 'stages/build_reps'
