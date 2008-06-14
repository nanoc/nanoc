module Nanoc::BinaryFilters

  class Thumbnail < Nanoc::BinaryFilter

    identifier :thumbnail

    def run(file)
      require 'image_science'

      # Get temporary file path
      tmp_file = Tempfile.new('filter')
      tmp_path = tmp_file.path
      tmp_file.close

      # Create thumbnail
      ImageScience.with_image(file.path) do |img|
        img.thumbnail(@asset_rep.thumbnail_size || 150) do |thumbnail|
          thumbnail.save(tmp_path)
        end
      end

      # Return thumbnail file
      File.open(tmp_path)
    end

  end

end
