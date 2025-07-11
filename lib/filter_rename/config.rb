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
    OPTIONS = { date_format: { args: "FORMAT",
                               desc: "Describes the date FORMAT for <mtime> and <ctime> targets.",
                               long: "This is how the <mtime> and <ctime> targets will be formatted\n" \
                                     "for each file read, unless the *essential_tags* option is on.\n" \
                                     "The allowed placeholders are prefixed with a percentage % char\n" \
                                     "and are the same used by the *date* command.\n" \
                                     "Use the *date* man page to get more info.",
                               default: "%Y-%m-%d" },
                hash_type: { args: "ALGORITHM",
                             desc: "Use one of the ALGORITHM among sha1, sha2, md5 to create the <hash> target.",
                             long: "It preload the <hash> target with one of the allowed value\n" \
                                   "sha1, sha2, or md5.\n" \
                                   "Just as reminder, md5 is the less safe but the quicker to be\n" \
                                   "executed, sha2 is the slowest but the safest.",
                             default: "md5" },
                hash_on_tags: { args: nil,
                                desc: "Enable or not the hash calculation for each file.",
                                long: "Hash calculation can be expensive, that's why it is disabled\n" \
                                      "by default and the <hash> target is not created.",
                                default: false },
                hash_if_exists: { args: nil,
                                  desc: "Prints or not the hash in case the file exists.",
                                  long: "This option shows the hash of the two files when the *dry* or\n" \
                                        "*apply* operation is triggered and a conflict is raised.\n" \
                                        "Looking at the hash code would be easier to understand wheter or\n" \
                                        "not the renaming failure is caused by two clones or two totally\n" \
                                        "different files that the filters transformed in the same file.",
                                  default: true },
                counter_length: { args: "NUMBER",
                                  desc: "The minimum length of the counter padded by zeros.",
                                  long: "This is the length of the counter in terms of NUMBER of total\n" \
                                        "chars, it means that, when the counter lenght is less than NUMBER\n" \
                                        "a certain number of '0' is prepended.",
                                  default: "3" },
                counter_start: { args: "NUMBER",
                                 desc: "Starts the counter from NUMBER+1 in place of the default.",
                                 long: "This is the way to set the initial counter that affect the\n" \
                                       "<count> target.\n" \
                                       "Be aware that will start from NUMBER+1 for implementation reasons,\n" \
                                       "so to have as 0 the first element just set NUMBER to -1",
                                 default: "0" },
                targets: { args: "FORMAT",
                           desc: "Print the targets as a *short* one-line or a *long* one-column list.",
                           long: "This option is to show or not a more compact list of the available\n" \
                                 "targets for the given file(s).\n" \
                                 "The allowed values are *short* or *long*.",
                           default: "short" },
                pdf_metadata: { args: nil,
                                desc: "Create the targets from the PDF files metadata.",
                                long: "This option enable the generation of targets from the metadata\n" \
                                      "embedded in the PDF files.",
                                default: true },
                image_metadata: { args: nil,
                                  desc: "Create the targets from the image files metadata.",
                                  long: "This option enable the generation of targets from the metadata\n" \
                                        "embedded in the supported image files.",
                                  default: true },
                mp3_metadata: { args: nil,
                                desc: "Create the targets from the mp3 files metadata.",
                                long: "This option enable the generation of targets from the metadata\n" \
                                      "embedded in the mp3 files.",
                                default: "true" },
                mimemagic: { args: nil,
                             desc: "Create the extra targets depending from the file's mimetype.",
                             long: "Disabling it, disable all the extra targets' calculation\n" \
                                   "based on the file's mimetype.",
                             default: true },
                essential_tags: { args: nil,
                                  desc: "Define whether or not to enable only essential targets.",
                                  long: "Setting it to true the basic targets only which involve\n" \
                                        "the file name, path, and extension, will be calculated.\n" \
                                        "This is useful to use less memory or to skip\n" \
                                        "those data that can't be calculated in case of a file list\n" \
                                        "is served by the pipeline.",
                                  default: false },
                check_source: { args: nil,
                                desc: "Define whether or not to enable the source files checking.",
                                long: "Setting it to false the source files aren't checked out\n" \
                                      "and a list of files not necessarily in the same machine\n" \
                                      "could be provided using the pipeline as an input.\n" \
                                      "Combined with essential_tags to true and mimemagic to false\n" \
                                      "is useful to avoid errors in that last scenario.",
                                default: true } }.freeze

    attr_reader(*OPTIONS.keys)

    def initialize(cfg)
      @date_format = cfg[:date_format] || "%Y-%m-%d"
      @hash_type = cfg[:hash_type].to_sym || :md5
      @hash_on_tags = cfg[:hash_on_tags] || false
      @hash_if_exists = cfg[:hash_if_exists] || true
      @counter_length = cfg[:counter_length] || 3
      @counter_start = cfg[:counter_start] || 0
      @targets = cfg[:targets].to_sym || :short
      @pdf_metadata = cfg[:pdf_metadata].nil? ? true : cfg[:pdf_metadata].to_boolean
      @image_metadata = cfg[:image_metadata].nil? ? true : cfg[:image_metadata].to_boolean
      @mp3_metadata = cfg[:mp3_metadata].nil? ? true : cfg[:mp3_metadata].to_boolean
      @mimemagic = cfg[:mimemagic].nil? ? true : cfg[:mimemagic].to_boolean
      @essential_tags = cfg[:essential_tags].nil? ? false : cfg[:essential_tags].to_boolean
      @check_source = cfg[:check_source].nil? ? true : cfg[:check_source].to_boolean
    end
  end

  #
  # Filter configurations.
  #
  class FilterConfig
    OPTIONS = { word_separator: { args: "CHARACTER",
                                  desc: "Define the CHARACTER that separates two words.",
                                  long: "This options affects the way a string is split in words,\n" \
                                        "and all the filters that operate with words will use this CHARACTER\n" \
                                        "to define the sequence of the word itself which can contain all characters\n" \
                                        "except CHARACTER.",
                                  default: " " },
                number_separator: { args: "CHARACTER",
                                    desc: "Define the CHARACTER that joins two or more numbers.",
                                    long: "This option configure the CHARACTER that will join\n" \
                                          "two or more numbers in the swap-number filter when an interval\n" \
                                          "is used as first parameter.",
                                    default: "." },
                # This one is unused
                # occurrence_separator: { args: "CHARACTER"
                #                         default: "-" },
                target: { args: "TARGET",
                          desc: "This is the TARGET name where the filters are operating",
                          long: "Switching to one of the available targets allows to alter their content\n" \
                                "directly using a chain of filters.\n" \
                                "Targets can be read-write or read-only, the former reflect data that will\n" \
                                "be write back to the file.\n" \
                                "Also custom targets can be defined just to hold text temporarily that can\n" \
                                "be transfered later to other targets.\n" \
                                "This option is the same as using the *--select* filter",
                          default: "name" },
                ignore_case: { args: nil,
                               desc: "Ignore or not the character case when searching for strings",
                               long: "This option allows to ignore the case during the search and replace\n" \
                                     "operations, doesn't matter which type of filter is involved",
                               default: true },
                lang: { args: "LANG",
                        desc: "Set the default LANG code for the replace-date filter.",
                        long: "This option is used by the replace-date filter to translate groups\n" \
                              "of words containing the months or day of weeks from a language to another",
                        default: "en" },
                grep: { args: "REGEXP",
                        desc: "Limit the file scope to only those matching the REGEXP pattern.",
                        long: "This options include or exclude from the following filters those\n" \
                              "files matching the REGEXP pattern",
                        default: ".*" },
                grep_on_dest: { args: nil,
                                desc: "Exec the grep option on the destination in place of the source filename",
                                long: "To limit the files to be involved in the changes you can apply the\n" \
                                      "grep option on the source or destination filename.\n" \
                                      "By default it is executed on the source, while this option allows\n" \
                                      "to select the destination filename.\n" \
                                      "Be aware that the destination changes according to all the previous\n" \
                                      "filters applied.",
                                default: false },
                grep_exclude: { args: nil,
                                desc: "Invert the logic to exclude the files matching the regular expression.",
                                long: "With this option the grep options will be used to exclude the files\n" \
                                      "matching the regular expression, from the next filters.",
                                default: false },
                grep_target: { args: "TARGET",
                               desc: "Use the specific TARGET to execute the grep match.",
                               long: "With this option you can limit the matching to only one of the available\n" \
                                     "TARGETs instead of considering the full filename.\n" \
                                     "So, for example, it comes in handy to skip the full path from the\n" \
                                     "process or consider only the file name or folder.",
                               default: "full_filename" } }.freeze

    attr_accessor(*OPTIONS.keys)

    def initialize(cfg)
      @word_separator = cfg[:word_separator] || " "
      @number_separator = cfg[:number_separator] || "."
      # Unused property
      @occurrence_separator = cfg[:occurrence_separator] || "-"
      @target = cfg[:target].to_sym || :name
      @ignore_case = cfg[:ignore_case].nil? ? true : cfg[:ignore_case].to_boolean
      @lang = (cfg[:lang] || :en).to_sym
      @macro = cfg[:macro] || {}
      @grep = cfg[:grep] || ".*"
      @grep_on_dest = cfg[:grep_on_dest].nil? ? false : cfg[:grep_on_dest].to_boolean
      @grep_exclude = cfg[:grep_exclude].nil? ? false : cfg[:grep_exclude].to_boolean
      @grep_target = (cfg[:grep_target] || :full_filename).to_sym
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
