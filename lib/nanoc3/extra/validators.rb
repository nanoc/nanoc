# encoding: utf-8

module Nanoc3::Extra

  # Nanoc3::Extra::Validators is the name for all validators.
  module Validators

    autoload 'W3C',   'nanoc3/extra/validators/w3c'
    autoload 'Links', 'nanoc3/extra/validators/links'

  end

end
