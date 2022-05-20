require 'fileutils'
require 'filter_rename/version'
require 'filter_rename/config'
require 'filter_rename/filter_base'
require 'filter_rename/filters'
require 'filter_rename/filter_pipe'
require 'filter_rename/filename'
require 'filter_rename/filename_factory'
require 'filter_rename/utils'

module FilterRename

  class Builder

    def initialize(options)
      @cfg = Config.new(options.global)
      @filters = FilterList.new(options.filters)
      @files = options.files
      @show_macro = options.show_macro
    end

    def preview
      raise MissingFiles if @files.empty?

      @filters.expand_macros!(@cfg.macro)

      Messages.label "Preview:"

      @files.each do |src|
        fp = FilterPipe.new(src, @filters, @cfg).apply
        Messages.diff(fp)
      end
    end

    def apply
      raise MissingFiles if @files.empty?

      @filters.expand_macros!(@cfg.macro)

      Messages.label "Apply:"
      @files.each do |src|

        fp = FilterPipe.new(src, @filters, @cfg).apply

        if fp.changed?
          old_data = fp.rename!

          if old_data[:full_filename]
            Messages.renamed!(old_data, fp.dest)
            Messages.changed_tags(fp, old_data, false) if fp.source.class.has_writable_tags
          elsif fp.source.class.has_writable_tags
            Messages.changed_tags(fp, old_data)
          else
            Messages.file_exists(fp)
          end

        else
          Messages.skipping(fp)
        end
      end
    end

    def globals
      Messages.label 'Global configurations:'
      Messages.config_list @cfg.global
    end

    def configs
      Messages.label 'Filter\'s configurations:'
      Messages.config_list @cfg.filter
    end

    def words
      Messages.label 'Groups and subgroups of words available for translation:'
      Messages.config_multilist @cfg.words
    end

    def dry_run
      raise MissingFiles if @files.empty?

      @filters.expand_macros!(@cfg.macro)
      cache = []

      Messages.label "Dry Run:"
      @files.each do |src|

        fp = FilterPipe.new(src, @filters, @cfg).apply

        if fp.unchanged?
          Messages.skipping(fp)
        elsif (cache.include?(fp.dest.full_filename) || fp.dest.exists?)
          if fp.source.full_filename == fp.dest.full_filename
            Messages.changed_tags(fp)
          else
            Messages.file_exists(fp)
          end
        else
          Messages.renamed(fp)
          Messages.changed_tags(fp, {}, false) if fp.source.class.has_writable_tags
          cache << fp.dest.full_filename
        end
      end
    end

    def targets
      raise MissingFiles if @files.empty?

      Messages.label 'Targets:'
      @files.each do |src|

        fname = FilenameFactory.create(src, @cfg.global)

        Messages.multi fname.full_filename
        Messages.send(@cfg.global.targets == :short ? :short_targets : :long_targets, fname)
      end
    end

    def macros
      Messages.label 'Macros:'
      Messages.list @cfg.macro.get_macros
    end

    def show_macro
      Messages.label "Macro: #{@show_macro}"
      macro = @cfg.macro.get_macro(@show_macro)
      if macro.class == Array
        macro.each do |k|
          Messages.item k.keys.first.to_s + ': ' + k.values.first.map { |x| '"' + x.to_s.green + '"' }.join(',')
        end
      elsif macro.class == Hash
        macro.each do |k, v|
          Messages.item k.to_s + ': ' +  v.map { |x| '"' + x.to_s.green + '"'  }.join(', ')
        end
      end
    end

  end

end
