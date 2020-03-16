require 'fastimage'
require 'exiv2'

module FilterRename

  class ImageFilename < Filename

    def initialize(fname, cfg)
      super fname, cfg

      image = FastImage.new(fname)
      @width = image.size[0].to_s
      @height = image.size[1].to_s

      [@width, @height].map(&:readonly!)

      if cfg.image_metadata
        image = Exiv2::ImageFactory.open(fname)
        image.read_metadata

        image.exif_data.each do |key, value|
          metadata_to_var!(key, value, true)
        end unless image.exif_data.nil?
      end
    end
  end

end
