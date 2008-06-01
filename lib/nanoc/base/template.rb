module Nanoc

  # A Nanoc::Template represents a template, which can be used for creating
  # new pages (but pages don't need to be generated off pages).
  class Template

    # The Nanoc::Site this template belongs to.
    attr_accessor :site

    # The name of this template.
    attr_reader :name

    # The raw content a page created using this template will have.
    attr_reader :page_content

    # A hash containing the attributes a page created using this template will
    # have.
    attr_reader :page_attributes

    # Creates a new template.
    #
    # +name+:: The name of this template.
    #
    # +page_content+:: The raw content a page created using this template will
    #                  have.
    #
    # +page_attributes+:: A hash containing the attributes a page created
    #                     using this template will have.
    def initialize(page_content, page_attributes, name)
      @page_content     = page_content
      @page_attributes  = page_attributes.clean
      @name             = name
    end

    # Saves the template in the database, creating it if it doesn't exist yet
    # or updating it if it already exists. Tells the site's data source to
    # save the template.
    def save
      @site.data_source.loading do
        @site.data_source.save_template(self)
      end
    end

    # Renames the template. Tells the site's data source to rename the
    # template.
    def move_to(new_name)
      @site.data_source.loading do
        @site.data_source.move_template(self, new_name)
      end
    end

    # Deletes the template. Tells the site's data source to delete the
    # template.
    def delete
      @site.data_source.loading do
        @site.data_source.delete_template(self)
      end
    end

  end

end
