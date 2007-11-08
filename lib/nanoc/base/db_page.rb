try_require 'active_record'

module Nanoc
  begin
    class DBPage < ActiveRecord::Base
      set_table_name 'pages'
    end
  rescue NameError
  end
end
