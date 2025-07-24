# frozen_string_literal: true

require "fileutils"
require "filter_rename/version"
require "filter_rename/config"
require "filter_rename/filter_base"
require "filter_rename/filters"
require "filter_rename/filter_pipe"
require "filter_rename/filename"
require "filter_rename/filename_factory"
require "filter_rename/utils"

module FilterRename
  #
  # Facade class for all the operations.
  #
  class Builder
    def initialize(options)
      @cfg = Config.new(options.global)
      @filters = FilterList.new(options.filters)
      @files = options.files
      @show_macro = options.show_macro
      @help_config = options.help_config
    end

    def diff
      expand_files!
      raise MissingFiles if @files.empty?

      @filters.expand_macros!(@cfg.macro)

      Messages.label "Diff:"

      @files.each do |src|
        fp = FilterPipe.new(src, @filters, @cfg).apply
        Messages.diff(fp)
      end
    end

    def apply
      expand_files!
      raise MissingFiles if @files.empty?

      @filters.expand_macros!(@cfg.macro)
      renamed = 0
      skipped = 0
      errors = 0

      Messages.label "Apply:"
      @files.each do |src|
        fp = FilterPipe.new(src, @filters, @cfg).apply

        if fp.changed?
          old_data = fp.rename!

          if old_data[:full_filename]
            Messages.renamed!(old_data, fp.dest)
            Messages.changed_tags(fp, old_data, header: false) if fp.source.class.writable_tags?
            renamed += 1
          elsif fp.source.class.writable_tags?
            Messages.changed_tags(fp, old_data)
            renamed += 1
          else
            Messages.file_exists(fp)
            Messages.file_hash(fp, @cfg.global.hash_type) if @cfg.global.hash_if_exists
            errors += 1
          end
        else
          Messages.skipping(fp)
          skipped += 1
        end
      end
      Messages.renaming_summary(renamed, skipped, errors)
    end

    def globals
      Messages.label "Global configurations:"
      Messages.config_list @cfg.global
    end

    def configs
      Messages.label "Filter's configurations:"
      Messages.config_list @cfg.filter
    end

    def words
      Messages.label "Groups and subgroups of words available for translation:"
      Messages.config_multilist @cfg.words
    end

    def dry_run
      expand_files!
      raise MissingFiles if @files.empty?

      @filters.expand_macros!(@cfg.macro)
      cache = {}
      renamed = 0
      skipped = 0
      errors = 0

      Messages.label "Dry Run:"
      @files.each do |src|
        fp = FilterPipe.new(src, @filters, @cfg).apply

        if fp.unchanged?
          Messages.skipping(fp)
          skipped += 1
        elsif cache.keys.include?(fp.dest.full_filename) || fp.dest.exists?
          if fp.source.full_filename == fp.dest.full_filename
            Messages.changed_tags(fp)
          else
            Messages.file_exists(fp)
            Messages.file_hash(fp, @cfg.global.hash_type, cache[fp.dest.full_filename]) if @cfg.global.hash_if_exists
            errors += 1
          end
        else
          Messages.renamed(fp)
          Messages.changed_tags(fp, {}, header: false) if fp.source.class.writable_tags?
          cache[fp.dest.full_filename] = fp.dest
          renamed += 1
        end
      end
      Messages.renaming_summary(renamed, skipped, errors)
    end

    def targets
      expand_files!
      raise MissingFiles if @files.empty?

      view = @cfg.global.inline_targets ? :inline_targets : :column_targets
      Messages.label "Targets:"
      @files.each do |src|
        fname = FilenameFactory.create(src, @cfg.global)

        Messages.multi fname.full_filename
        Messages.send(view, fname)
      end
    end

    def values
      expand_files!
      raise MissingFiles if @files.empty?

      view = @cfg.global.inline_targets ? :inline_target_values : :column_target_values
      Messages.label "Target values:"
      @files.each do |src|
        fname = FilenameFactory.create(src, @cfg.global)

        Messages.multi fname.full_filename
        Messages.send(view, fname)
      end
    end

    def macros
      Messages.label "Macros:"
      Messages.list @cfg.macro.macros
    end

    def show_macro
      Messages.label "Macro: #{@show_macro}"
      macro = @cfg.macro.get_macro(@show_macro)
      if macro.instance_of?(Array)
        macro.each do |k|
          Messages.item "#{k.keys.first}: " + k.values.first.map { |x| "\"#{x.to_s.green}\"" }.join(",")
        end
      elsif macro.instance_of?(Hash)
        macro.each do |k, v|
          Messages.item "#{k}: " + v.map { |x| "\"#{x.to_s.green}\"" }.join(", ")
        end
      end
    end

    def help_config
      name = @help_config.downcase.gsub("-", "_").gsub(/^--/, "")

      if name =~ /^g_/
        name = name.gsub(/^g_/, "")
        @help_config = GlobalConfig::OPTIONS[name.to_sym]
      elsif @help_config =~ /^f_/
        name = name.gsub(/^f_/, "")
        @help_config = FilterConfig::OPTIONS[name.to_sym]
      elsif FilterConfig::OPTIONS.key?(name.to_sym)
        @help_config = FilterConfig::OPTIONS[name.to_sym]
      elsif GlobalConfig::OPTIONS.key?(name.to_sym)
        @help_config = GlobalConfig::OPTIONS[name.to_sym]
      else
        raise InvalidOption, name
      end
      Messages.help_option name, @help_config
    end

    private

    def expand_files!
      @files = @files.map do |f|
        f = File.expand_path(f.chomp)
        raise FileNotFound, f if @cfg.global.check_source && !File.exist?(f)

        f
      end
    end
  end
end
