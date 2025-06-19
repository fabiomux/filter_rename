# frozen_string_literal: true

require "mimemagic"
require "fileutils"
require "differ"
require "digest"

module FilterRename
  #
  # Factory class that returns the
  # related file handler depending
  # from its file type.
  #
  class FilenameFactory
    def self.create(fname, cfg)
      return Filename.new(fname, cfg) if File.directory?(fname) || !cfg.mimemagic

      magic = MimeMagic.by_magic(File.open(fname))
      mediatype, type, subtype = magic.nil? ? %w[unknown unknown unknown] : [magic.mediatype, magic.type, magic.subtype]

      if (File.read(fname, 3) == "ID3") && (mediatype == "audio")
        require "filter_rename/filetype/mp3_filename"
        res = Mp3Filename.new(fname, cfg)
      elsif (mediatype == "audio") && (%w[flac mp4 ogg].include? subtype)
        require "filter_rename/filetype/audio_filename"
        res = AudioFilename.new(fname, cfg)
      elsif (mediatype == "image") && (!["vnd.djvu+multipage"].include? type.split("/")[1])
        # supported types: jpeg, png
        require "filter_rename/filetype/image_filename"
        res = ImageFilename.new(fname, cfg)
      elsif type == "application/pdf"
        require "filter_rename/filetype/pdf_filename"
        res = PdfFilename.new(fname, cfg)
      else
        res = Filename.new(fname, cfg)
      end

      res
    end
  end
end
