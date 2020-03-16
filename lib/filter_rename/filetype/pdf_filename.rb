require 'pdf-reader'

module FilterRename

  class PdfFilename < Filename

    def initialize(fname, cfg)
      super fname, cfg

      if cfg.pdf_metadata

        pdfinfo = PDF::Reader.new(fname)

        @page_count = pdfinfo.page_count.to_s
        @page_count.readonly!

        pdfinfo.info.each do |key, value|
          metatag_to_var!(key.to_s.gsub(/([A-Z])([^A-Z]+)/, '\1\2 ').strip, value, true)
        end unless pdfinfo.info.nil?
      end
    end
  end

end
