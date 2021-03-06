require 'mimemagic'
require 'fileutils'
require 'differ'
require 'digest'

module FilterRename

  class FilenameFactory

    def self.create(fname, cfg)

      return Filename.new(fname, cfg) if File.directory?(fname)

      magic = MimeMagic.by_magic(File.open(fname))
      mediatype, type = magic.nil? ? ['unknown', 'unknown'] : [magic.mediatype, magic.type]

      if (IO.read(fname, 3) == 'ID3') && (mediatype == 'audio')
        require 'filter_rename/filetype/mp3_filename'
        res = Mp3Filename.new(fname, cfg)
      elsif ((mediatype == 'image') && (! ['vnd.djvu+multipage'].include? type.split('/')[1]))
        # supported types: jpeg, png
        require 'filter_rename/filetype/image_filename'
        res = ImageFilename.new(fname, cfg)
      elsif (type == 'application/pdf')
        require 'filter_rename/filetype/pdf_filename'
        res = PdfFilename.new(fname, cfg)
      else
        res = Filename.new(fname, cfg)
      end

      res
    end

  end

end
