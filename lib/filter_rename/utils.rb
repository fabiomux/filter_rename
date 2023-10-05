# frozen_string_literal: true

require "date"
require "digest"

#
# Util classes collection.
#
module FilterRename
  FILE_SIZES = %w[B KB MB GB TB].freeze

  class Boolean; end # rubocop:disable Lint/EmptyClass

  #
  # Transform a TrueClass to boolean.
  #
  class ::TrueClass
    def to_boolean
      to_s.to_boolean
    end
  end

  #
  # Transform a FalseClass to boolean.
  #
  class ::FalseClass
    def to_boolean
      to_s.to_boolean
    end
  end

  #
  # Mixin for readable variables.
  #
  module ReadableVariables
    def basic!
      @custom = false
      self
    end

    def custom?
      @custom == true || @custom.nil?
    end

    def readonly!
      @writable = false
      self
    end

    def writable?
      @writable || @writable.nil?
    end
  end

  class ::Integer
    include ReadableVariables
  end

  #
  # String class patch.
  #
  class ::String
    include ReadableVariables

    def black
      "\033[30m#{self}\033[0m"
    end

    def red
      "\033[31m#{self}\033[0m"
    end

    def green
      "\033[32m#{self}\033[0m"
    end

    def yellow
      "\033[33m#{self}\033[0m"
    end

    def blue
      "\033[34m#{self}\033[0m"
    end

    def magenta
      "\033[35m#{self}\033[0m"
    end

    def cyan
      "\033[36m#{self}\033[0m"
    end

    def gray
      "\033[37m#{self}\033[0m"
    end

    def bg_black
      "\033[40m#{self}\0330m"
    end

    def bg_red
      "\033[41m#{self}\033[0m"
    end

    def bg_green
      "\033[42m#{self}\033[0m"
    end

    def bg_brown
      "\033[43m#{self}\033[0m"
    end

    def bg_blue
      "\033[44m#{self}\033[0m"
    end

    def bg_magenta
      "\033[45m#{self}\033[0m"
    end

    def bg_cyan
      "\033[46m#{self}\033[0m"
    end

    def bg_gray
      "\033[47m#{self}\033[0m"
    end

    def bold
      "\033[1m#{self}\033[22m"
    end

    def reverse_color
      "\033[7m#{self}\033[27m"
    end

    def cr
      "\r#{self}"
    end

    def clean
      "\e[K#{self}"
    end

    def new_line
      "\n#{self}"
    end

    def parametrize
      split(/(?<!\\),/).map { |x| x.gsub('\,', ",") }
    end

    def to_boolean
      self == "true"
    end

    def to_filter
      Object.const_get("FilterRename::Filters::#{to_s.split(/_|-/).map(&:capitalize).join}")
    end

    def to_switch
      scan(/[A-Z][a-z0-9]*/).map(&:downcase).join "-"
    end

    def change_date_format(args)
      format_src = args[:format_src]
      format_dest = args[:format_dest]
      short_months = args[:short_months]
      long_months = args[:long_months]
      long_days = args[:long_days]
      short_days = args[:short_days]

      str = clone

      regexp = format_src.gsub("<B>", "(#{long_months.join("|")})").gsub("<b>", "(#{short_months.join("|")})")
                         .gsub("<A>", "(#{long_days.join("|")})").gsub("<a>", "(#{short_days.join("|")})")
                         .gsub("<Y>", "[0-9]{4,4}").gsub(/<(d|m|y|H|I|M|S|U)>/, "[0-9]{2,2}")
                         .gsub("<u>", "[0-9]{1,1}")

      to_replace = str.scan(Regexp.new("(#{regexp})", true))

      unless to_replace.empty?
        to_replace = to_replace.pop
        template = format_src.gsub(/<([a-zA-Z])>/, '%\1')
        d = Date.strptime(to_replace[0], template)

        str.gsub! to_replace[0], d.strftime(format_dest.gsub(/<([a-zA-Z])>/, '%\1'))
      end

      str
    end

    def map_number_with_index(&block)
      gsub(/\d+/).with_index(&block)
    end

    def get_number(idx)
      scan(/\d+/)[idx]
    end

    def numbers
      scan(/\d+/)
    end
  end

  #
  # Format the error messages.
  #
  class Messages
    def self.error(err)
      if err.instance_of?(String)
        puts "[E] ".bold.red + err
      else
        warn "Error! ".bold.red + err.message
      end
    end

    def self.warning(msg)
      puts "[W] ".bold.yellow + msg
    end

    def self.ok(msg)
      puts "[V] ".bold.green + msg
    end

    def self.multi(msg)
      puts "[*] ".bold.magenta + msg
    end

    def self.diff(fpipe)
      puts fpipe.diff
    end

    def self.renamed(fpipe)
      if fpipe.source.full_path == fpipe.dest.full_path
        Messages.ok "#{fpipe.source.filename} #{">".bold.green} #{fpipe.dest.filename}"
      else
        Messages.ok "#{fpipe.source.filename} #{">".bold.green} #{fpipe.dest.full_filename}"
      end
    end

    def self.renamed!(old_data, renamed)
      if old_data[:full_path] == renamed.full_path
        Messages.ok "#{old_data[:filename]} #{">".bold.green} #{renamed.filename}"
      else
        Messages.ok "#{old_data[:filename]} #{">".bold.green} #{renamed.full_filename}"
      end
    end

    def self.label(text)
      puts "#{"[/]".bold.blue} #{text}"
    end

    def self.skipping(fpipe)
      puts "[X] ".bold.yellow + "Skipping <#{fpipe.source.filename}>, no changes!"
    end

    # rubocop:disable Style/HashEachMethods
    def self.changed_tags(fpipe, old_data = {}, header: true)
      Messages.ok "<#{fpipe.source.filename}> tags changed:" if header
      old_source = old_data.empty? ? fpipe.source.values : old_data

      fpipe.dest.values.each do |k, v|
        next unless (v.to_s != old_source[k].to_s) && fpipe.source.writable?(k) && fpipe.source.custom?(k)

        puts "    #{k}: ".rjust(15, " ")
                         .bold.green +
             (if old_source[k].to_s.empty?
                " ~ ".bold.red
              else
                old_source[k].to_s
              end) + " => ".bold.green + v.to_s
      end
    end
    # rubocop:enable Style/HashEachMethods

    def self.file_exists(fpipe)
      Messages.error "<#{fpipe.source.filename}> can't be renamed in <#{fpipe.dest.filename}>, it exists!"
    end

    def self.file_hash(fpipe, hash_type, cached = nil)
      raise UnknownHashCode, hash_type unless %i[sha1 sha2 md5].include?(hash_type.to_sym)

      klass = Object.const_get("Digest::#{hash_type.to_s.upcase}")
      hash_src = klass.file fpipe.source.filename
      hash_dest = cached ? klass.file(cached.original) : klass.file(fpipe.dest.filename)

      puts "    #{hash_src == hash_dest ? "[=]".green : "[>]".red} " \
           "#{hash_type.to_s.upcase} source: " \
           "#{hash_src.to_s.send(hash_src == hash_dest ? :green : :red)}"
      puts "    #{hash_src == hash_dest ? "[=]".green : "[<]".red} " \
           "#{hash_type.to_s.upcase} dest:   " \
           "#{hash_dest.to_s.send(hash_src == hash_dest ? :green : :red)}"
    end

    def self.short_targets(ffilters)
      list [ffilters.targets[:readonly].map { |s| "<#{s.to_s.delete("@")}>" }.join(", ")], :red, "-"
      list [ffilters.targets[:writable].map { |s| "<#{s.to_s.delete("@")}>" }.join(", ")], :green, "+"
      puts ""
    end

    def self.long_targets(ffilters)
      list ffilters.targets[:readonly].map { |s| "<#{s.to_s.delete("@")}>" }, :red, "-"
      list ffilters.targets[:writable].map { |s| "<#{s.to_s.delete("@")}>" }, :green, "+"
      puts ""
    end

    def self.item(idx, color = :green, char = ">")
      puts "[#{char}] ".bold.send(color) + idx
    end

    def self.list(items, color = :green, char = ">")
      items.each { |x| Messages.item(x, color, char) }
    end

    def self.config_list(items, color = :green, char = ">")
      items.instance_variables.each do |k|
        Messages.item("#{k.to_s.gsub(/@/, "")}: #{items.instance_variable_get(k)}", color, char)
      end
    end

    def self.config_multilist(items, color = :green, char = ">")
      items.instance_variables.each do |k|
        Messages.item("#{k.to_s.gsub(/@/, "")}: [#{items.instance_variable_get(k).keys.join(", ")}]", color, char)
      end
    end
  end

  #
  # Index out of range error.
  #
  class IndexOutOfRange < StandardError
    def initialize(values)
      super "Invalid index '#{values[0]}' out of the range 1..#{values[1]}, -#{values[1]}..-1"
    end
  end

  #
  # Unknown hash error.
  #
  class UnknownHashCode < StandardError
    def initialize(hash_type)
      super "Invalid hash type: #{hash_type}"
    end
  end

  #
  # Invalid macro error.
  #
  class InvalidMacro < StandardError
    def initialize(macro)
      super "Invalid macro: #{macro}"
    end
  end

  #
  # Invalid target error.
  #
  class InvalidTarget < StandardError
    def initialize(target)
      super "Invalid target: #{target}"
    end
  end

  #
  # Invalid filter setting error.
  #
  class InvalidFilterSetting < StandardError
    def initialize(name)
      super "Invalid configuration setting: #{name}"
    end
  end

  #
  # Invalid word's group.
  #
  class InvalidWordsGroup < StandardError
    def initialize(group)
      super "Invalid words group: #{group}"
    end
  end

  #
  # Invalid words section.
  #
  class InvalidWordsSection < StandardError
    def initialize(group, section)
      super "Invalid words section for #{group}: #{section}"
    end
  end

  #
  # Invalid words index.
  #
  class InvalidWordsIndex < StandardError
    def initialize(group, section, idx)
      super "Missing the item #{idx + 1} in #{group}/#{section} words section"
    end
  end

  #
  # File not found error.
  #
  class FileNotFound < StandardError
    def initialize(filename)
      super "File not found: #{filename}"
    end
  end

  #
  # Missing files error.
  #
  class MissingFiles < StandardError
    def initialize
      super "No filenames specified"
    end
  end

  #
  # Existing file error.
  #
  class ExistingFile < StandardError
    def initialize(filename)
      super "The file #{filename} already exists and won't be overwrite"
    end
  end

  #
  # Ctrl + C message error.
  #
  class Interruption < StandardError
    def initialize
      super "Ok ok... Exiting!"
    end
  end

  Differ.format = :color

  Signal.trap("INT") { raise Interruption }

  Signal.trap("TERM") { raise Interruption }
end
