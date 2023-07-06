# frozen_string_literal: true

require "pdf-reader"

module FilterRename
  #
  # Pdf files tags handling.
  #
  class PdfFilename < Filename
    def initialize(fname, cfg)
      super fname, cfg

      return unless cfg.pdf_metadata

      pdfinfo = PDF::Reader.new(fname)

      @page_count = pdfinfo.page_count.to_s
      @page_count.readonly!

      return if pdfinfo.info.nil?

      pdfinfo.info.each do |key, value|
        metatag_to_var!(key.to_s.gsub(/([A-Z])([^A-Z]+)/, '\1\2 ').strip, value, readonly: true)
      end
    end
  end
end
