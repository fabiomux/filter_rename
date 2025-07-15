# frozen_string_literal: true

require "fastimage"
require "exiv2"

module FilterRename
  #
  # Image files tags handling.
  #
  class ImageFilename < Filename
    def initialize(fname, cfg)
      super fname, cfg

      image = FastImage.new(fname)
      @width = image.size[0].to_s
      @height = image.size[1].to_s

      [@width, @height].map(&:readonly!)

      load_image_data(fname) if cfg.image_metadata
    end

    def load_image_data(fname)
      image = Exiv2::ImageFactory.open(fname)
      image.read_metadata

      return if image.exif_data.nil?

      image.exif_data.each do |key, value|
        metadata_to_var!(key, value, true)
      end
    end
  end
end
