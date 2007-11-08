require '../../../lib/nanoc.rb'

namespace :nanoc do
  namespace :db do

    task :create do
      nanoc_require 'active_record'
      $nanoc_compiler.prepare

      # Create table
      ActiveRecord::Schema.define do
        create_table :pages, :force => true do |t|
          t.column :content, :text
          t.column :path,    :string
          t.column :meta,    :text
        end
      end

      # Create first page
      Nanoc::DBPage.create :path    => '/',
                           :content => 'This is a sample root page. Please edit me!',
                           :meta    => "# Built-in\n\n# Custom\ntitle: A New Page\n"
    end

  end
end
