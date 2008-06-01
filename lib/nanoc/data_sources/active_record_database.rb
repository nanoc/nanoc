begin ; require 'active_record' ; rescue LoadError ; end

module Nanoc::DataSources

  # TODO document
  class ActiveRecordDatabase < Nanoc::DataSource

    ########## Helper classes ##########

    begin

      class DatabasePage < ActiveRecord::Base # :nodoc:
        set_table_name 'pages'
      end

      class DatabasePageDefaults < ActiveRecord::Base # :nodoc:
        set_table_name 'page_defaults'
      end

      class DatabaseTemplate < ActiveRecord::Base # :nodoc:
        set_table_name 'templates'
      end

      class DatabaseLayout < ActiveRecord::Base # :nodoc:
        set_table_name 'layouts'
      end

      class DatabaseCodePiece < ActiveRecord::Base # :nodoc:
        set_table_name 'code_pieces'
      end

    rescue NameError
    end

    ########## Attributes ##########

    identifier :active_record_database

    ########## Preparation ##########

    def up # :nodoc:
      require 'active_record'

      # Connect to the database
      ActiveRecord::Base.establish_connection(@site.config[:database])
    end

    def down # :nodoc:
      # Disconnect from the database
      ActiveRecord::Base.remove_connection
    end

    def setup # :nodoc:
      # Create tables
      schema = ActiveRecord::Schema
      schema.verbose = false
      schema.define do

        create_table :pages, :force => true do |t|
          t.column :content,  :text
          t.column :attribs,  :text
          t.column :path,     :string
        end

        create_table :page_defaults, :force => true do |t|
          t.column :attribs,  :text
        end

        create_table :layouts, :force => true do |t|
          t.column :content,  :text
          t.column :attribs,  :string
          t.column :path,     :string
        end

        create_table :templates, :force => true do |t|
          t.column :content,  :text
          t.column :attribs,  :text
          t.column :name,     :string
        end

        create_table :code_pieces, :force => true do |t|
          t.column :name,     :string
          t.column :code,     :text
        end

      end

      DatabasePageDefaults.create :attribs => ''
    end

    def destroy
      # TODO implement
    end

    def update
      # TODO implement
    end

    ########## Pages ##########

    def pages # :nodoc:
      # Create Pages for each database object
      DatabasePage.find(:all).map do |page|
        # Read attributes
        attributes = YAML.load(page.attribs) || {}

        if attributes[:is_draft]
          # Skip drafts
          nil
        else
          # Create page
          Nanoc::Page.new(page.content, attributes, page.path)
        end
      end.compact
    end

    def save_page(page) # :nodoc:
      # Find or create database page
      database_page = DatabasePage.find_or_create_by_path(page.path)

      # Update attributes
      database_page.content = page.content(:raw)
      database_page.attribs = YAML.dump(page.attributes)
      database_page.path    = page.path

      # Save
      database_page.save
    end

    def move_page(page, new_path) # :nodoc:
      # TODO implement
    end

    def delete_page(page) # :nodoc:
      # TODO implement
    end

    ########## Page Defaults ##########

    def page_defaults # :nodoc:
      Nanoc::PageDefaults.new(YAML.load(DatabasePageDefaults.find(:first).attribs) || {})
    end

    def save_page_defaults(page_defaults) # :nodoc:
      # Find database page defaults
      database_page_defaults = DatabasePageDefaults.find(:first)

      # Update attributes
      database_page_defaults.attribs = YAML.dump(page_defaults.attributes)

      # Save
      database_page_defaults.save
    end

    ########## Layout ##########

    def layouts # :nodoc:
      DatabaseLayout.find(:all).map do |dbl|
        Nanoc::Layout.new(dbl.content, YAML.load(dbl.attribs) || {}, dbl.path)
      end
    end

    def save_layout(layout) # :nodoc:
      # Find or create database layout
      database_layout = DatabaseLayout.find_or_create_by_path(layout.path)

      # Update attributes
      database_layout.content = layout.content
      database_layout.attribs = YAML.dump(layout.attributes)
      database_layout.path    = layout.path

      # Save
      database_layout.save
    end

    def move_layout(layout, new_path) # :nodoc:
      # TODO implement
    end

    def delete_layout(layout) # :nodoc:
      # TODO implement
    end

    ########## Templates ##########

    def templates # :nodoc:
      DatabaseTemplate.find(:all).map do |dbt|
        Nanoc::Template.new(dbt.content, YAML.load(dbt.attribs) || {}, dbt.name)
      end
    end

    def save_template(template) # :nodoc:
      # Find or create database template
      database_template = DatabaseTemplate.find_or_create_by_name(template.name)

      # Update attributes
      database_template.content = template.page_content
      database_template.attribs = YAML.dump(template.page_attributes)
      database_template.name    = template.name

      # Save
      database_template.save
    end

    def move_template(template, new_name) # :nodoc:
      # TODO implement
    end

    def delete_template(template) # :nodoc:
      # TODO implement
    end

    ########## Code ##########

    def code # :nodoc:
      DatabaseCodePiece.find(:all).map { |p| p.code }.join("\n")
    end

    def save_code(code) # :nodoc:
      # TODO implement
    end

  end

end
