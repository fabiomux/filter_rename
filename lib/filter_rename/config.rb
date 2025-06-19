# frozen_string_literal: true

require "yaml"

module FilterRename
  #
  # Macro configurations.
  #
  class MacroConfig
    def initialize(cfg)
      cfg.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def get_macro(name)
      macro = instance_variable_get("@#{name.to_s.gsub(/[^a-zA-Z0-9,-_]/, "")}")
      raise InvalidMacro, name if macro.nil? || macro.to_s.empty?

      macro
    end

    def macros
      instance_variables.map { |msg| msg.to_s.gsub(/^@/, "") }
    end

    def self.create(name)
      { FilterRename::MacroConfig => name }
    end
  end

  #
  # Word filters configurations.
  #
  class WordsConfig
    def initialize(cfg)
      cfg.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def get_words(name, section, idx = nil)
      w = instance_variable_get("@#{name}")
      raise InvalidWordsGroup, name if w.nil? || name.to_s.empty?
      raise InvalidWordsSection.new(name, section) unless w.key? section.to_sym

      if idx.nil?
        w[section]
      elsif w[section].instance_of?(Array)
        raise InvalidWordsIndex.new(name, section, idx) unless idx < w[section].length

        w[section][idx].to_s
      else
        w[section].to_s
      end
    end
  end

  #
  # Global configurations.
  #
  class GlobalConfig
    attr_reader :date_format, :hash_type, :hash_on_tags, :hash_if_exists, :counter_length, :counter_start, :targets,
                :pdf_metadata, :image_metadata, :mp3_metadata, :mimemagic

    def initialize(cfg)
      @date_format = cfg[:date_format] || "%Y-%m-%d"
      @hash_type = cfg[:hash_type].to_sym || :md5
      @hash_on_tags = cfg[:hash_on_tags] || false
      @hash_if_exists = cfg[:hash_if_exists] || false
      @counter_length = cfg[:counter_length] || 4
      @counter_start = cfg[:counter_start] || 0
      @targets = cfg[:targets].to_sym || :short
      @pdf_metadata = cfg[:pdf_metadata].nil? ? true : cfg[:pdf_metadata].to_boolean
      @image_metadata = cfg[:image_metadata].nil? ? true : cfg[:image_metadata].to_boolean
      @mp3_metadata = cfg[:mp3_metadata].nil? ? true : cfg[:mp3_metadata].to_boolean
      @mimemagic = cfg[:mimemagic].nil? ? true : cfg[:mimemagic].to_boolean
    end
  end

  #
  # Filter configurations.
  #
  class FilterConfig
    attr_accessor :word_separator, :number_separator, :occurrence_separator, :target, :ignore_case, :lang, :grep,
                  :grep_on, :grep_exclude, :grep_target

    def initialize(cfg)
      @word_separator = cfg[:word_separator] || " "
      @number_separator = cfg[:number_separator] || "."
      @occurrence_separator = cfg[:occurrence_separator] || "-"
      @target = cfg[:target].to_sym || :name
      @ignore_case = cfg[:ignore_case].nil? ? true : cfg[:ignore_case].to_boolean
      @lang = (cfg[:lang] || :en).to_sym
      @macro = cfg[:macro] || {}
      @grep = cfg[:grep] || ".*"
      @grep_on = cfg[:grep_on].to_sym || :source
      @grep_exclude = cfg[:grep_exclude].to_boolean || false
      @grep_target = cfg[:grep_target].to_sym || :full_filename
    end
  end

  #
  # Proxy class for all configurations.
  #
  class Config
    attr_reader :filter, :global, :macro, :words

    def initialize(global = {})
      cfg = { filter: {}, global: {}, macro: {}, words: {} }

      load_file(File.expand_path(File.join(File.dirname(__FILE__), "..", "filter_rename.yaml")), cfg)
      load_file(File.join(Dir.home, ".filter_rename.yaml"), cfg)
      load_file(File.join(Dir.home, ".filter_rename", "config.yaml"), cfg)

      @filter = FilterConfig.new(cfg[:filter])
      @global = GlobalConfig.new(cfg[:global].merge(global))
      @macro  = MacroConfig.new(cfg[:macro].sort)
      @words  = WordsConfig.new(cfg[:words].sort)
    end

    private

    def load_file(filename, cfg = nil)
      return unless File.exist?(filename)

      @filename = filename
      yaml = YAML.load_file(filename)
      %i[filter global macro words].each do |s|
        cfg[s].merge!(yaml[s]) if yaml.key?(s)
      end
    end
  end
end
