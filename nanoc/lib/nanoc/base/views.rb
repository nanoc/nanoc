# frozen_string_literal: true

# TODO: Move this, once the load order is improved (i.e. the checksummer is
# loded after the views are).
Nanoc::Core::Checksummer.define_behavior(
  Nanoc::Core::View,
  Nanoc::Core::Checksummer::UnwrapUpdateBehavior,
)
