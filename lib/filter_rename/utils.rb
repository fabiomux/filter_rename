require 'date'

module FilterRename

  FILE_SIZES = ['B', 'KB', 'MB', 'GB', 'TB']

  class Boolean; end

  class ::TrueClass
    def to_boolean
      self.to_s.to_boolean
    end
  end

  class ::FalseClass
    def to_boolean
      self.to_s.to_boolean
    end
  end

  module ReadableVariables

    def readonly!
      @writable = false
      self
    end

    def writable?
      @writable || @writable == nil
    end
  end

  class ::Integer
    include ReadableVariables
  end

  class ::String
    include ReadableVariables

    def black;          "\033[30m#{self}\033[0m" end
    def red;            "\033[31m#{self}\033[0m" end
    def green;          "\033[32m#{self}\033[0m" end
    def yellow;         "\033[33m#{self}\033[0m" end
    def blue;           "\033[34m#{self}\033[0m" end
    def magenta;        "\033[35m#{self}\033[0m" end
    def cyan;           "\033[36m#{self}\033[0m" end
    def gray;           "\033[37m#{self}\033[0m" end
    def bg_black;       "\033[40m#{self}\0330m"  end
    def bg_red;         "\033[41m#{self}\033[0m" end
    def bg_green;       "\033[42m#{self}\033[0m" end
    def bg_brown;       "\033[43m#{self}\033[0m" end
    def bg_blue;        "\033[44m#{self}\033[0m" end
    def bg_magenta;     "\033[45m#{self}\033[0m" end
    def bg_cyan;        "\033[46m#{self}\033[0m" end
    def bg_gray;        "\033[47m#{self}\033[0m" end
    def bold;           "\033[1m#{self}\033[22m" end
    def reverse_color;  "\033[7m#{self}\033[27m" end
    def cr;             "\r#{self}" end
    def clean;          "\e[K#{self}" end
    def new_line;       "\n#{self}" end

    def parametrize
      self.split(/(?<!\\),/).map { |x| x.gsub('\,', ',') }
    end

    def to_boolean
      self == 'true'
    end

    def to_filter
      Object.const_get("FilterRename::Filters::#{self.to_s.split(/_|-/).map(&:capitalize).join}")
    end

    def to_switch
      self.scan(/[A-Z][a-z0-9]*/).map(&:downcase).join '-'
    end

    def change_date_format(args)
      format_src = args[:format_src]
      format_dest = args[:format_dest]
      short_months = args[:short_months]
      long_months = args[:long_months]
      long_days = args[:long_days]
      short_days = args[:short_days]

      str = self.clone

      regexp = format_src.gsub('<B>', "(#{long_months.join('|')})").gsub('<b>', "(#{short_months.join('|')})")
                         .gsub('<A>', "(#{long_days.join('|')})").gsub('<a>', "(#{short_days.join('|')})")
                         .gsub('<Y>', '[0-9]{4,4}').gsub(/<(d|m|y|H|I|M|S|U)>/, '[0-9]{2,2}')
                         .gsub('<u>', '[0-9]{1,1}')

      to_replace = str.scan(Regexp.new("(#{regexp})", true))

      unless to_replace.empty?
        to_replace = to_replace.pop
        template = format_src.gsub(/<([a-zA-Z])>/, '%\1')
        d = Date.strptime(to_replace[0], template)

        str.gsub! to_replace[0], d.strftime(format_dest.gsub(/<([a-zA-Z])>/, '%\1'))
      end

      str
    end

    def map_number_with_index
      self.gsub(/\d+/).with_index do |num, i|
        yield num, i
      end
    end

    def get_number(idx)
      self.scan(/\d+/)[idx]
    end
  end


  class Messages

    def self.error(e)
      if e.class == String
        puts '[E] '.bold.red + e
      else
        STDERR.puts 'Error! '.bold.red + e.message
      end
    end

    def self.warning(m)
      puts '[W] '.bold.yellow + m
    end

    def self.ok(m)
      puts '[V] '.bold.green + m
    end

    def self.multi(m)
      puts '[*] '.bold.magenta + m
    end

    def self.diff(fp)
      puts fp.diff
    end

    def self.renamed(fp)
      if fp.source.full_path != fp.dest.full_path
        Messages.ok "#{fp.source.filename} #{'>'.bold.green} #{fp.dest.full_filename}"
      else
        Messages.ok "#{fp.source.filename} #{'>'.bold.green} #{fp.dest.filename}"
      end
    end

    def self.renamed!(old_data, renamed)
      if old_data[:full_path] != renamed.full_path
        Messages.ok "#{old_data[:filename]} #{'>'.bold.green} #{renamed.full_filename}"
      else
        Messages.ok "#{old_data[:filename]} #{'>'.bold.green} #{renamed.filename}"
      end
    end


    def self.label(text)
      puts "#{'[/]'.bold.blue} #{text}"
    end

    def self.skipping(fp)
      puts '[X] '.bold.yellow + "Skipping <#{fp.source.filename}>, no changes!"
    end

    def self.changed_tags(fp, old_data = {}, header = true)
      Messages.ok "<#{fp.source.filename}> tags changed:" if header
      old_source = old_data.empty? ? fp.source.values : old_data

      fp.dest.values.each do |k, v|
        puts "    #{k}: ".bold.green + (old_source[k] || '-') + ' > '.bold.green + v if ((v != old_source[k]) && (!old_source[k].nil?))
      end
    end

    def self.file_exists(fp)
      Messages.error "<#{fp.source.filename}> can't be renamed in <#{fp.dest.filename}>, it exists!"
    end

    def self.short_targets(ff)
      self.list [ff.targets[:readonly].map { |s| "<#{s.to_s.delete('@')}>"}.join(', ')], :red, '-'
      self.list [ff.targets[:writable].map { |s| "<#{s.to_s.delete('@')}>"}.join(', ')], :green, '+'
      puts ''
    end

    def self.long_targets(ff)
      self.list ff.targets[:readonly].map { |s| "<#{s.to_s.delete('@')}>" }, :red, '-'
      self.list ff.targets[:writable].map { |s| "<#{s.to_s.delete('@')}>" }, :green, '+'
      puts ''
    end

    def self.item(i, color = :green, ch = '>')
      puts "[#{ch}] ".bold.send(color) + i
    end

    def self.list(items, color = :green, ch = '>')
      items.each { |x| Messages.item(x, color, ch) }
    end

    def self.config_list(items, color = :green, ch = '>')
      items.instance_variables.each { |k| Messages.item("#{k.to_s.gsub(/@/, '')}: #{items.instance_variable_get(k)}", color, ch) }
    end

    def self.config_multilist(items, color = :green, ch = '>')
      items.instance_variables.each { |k| Messages.item("#{k.to_s.gsub(/@/, '')}: [#{items.instance_variable_get(k).keys.join(', ')}]", color, ch) }
    end
  end

  class UnknownHashCode < StandardError
    def initialize(hash_type)
      super "Invalid hash type: #{hash_type}"
    end
  end

  class InvalidMacro < StandardError
    def initialize(macro)
      super "Invalid macro: #{macro}"
    end
  end

  class InvalidTarget < StandardError
    def initialize(target)
      super "Invalid target: #{target}"
    end
  end

  class InvalidFilterSetting < StandardError
    def initialize(name)
      super "Invalid configuration setting: #{name}"
    end
  end

  class InvalidWordsGroup < StandardError
    def initialize(group)
      super "Invalid words group: #{group}"
    end
  end

  class InvalidWordsSection < StandardError
    def initialize(group, section)
      super "Invalid words section for #{group}: #{section}"
    end
  end

  class InvalidWordsIndex < StandardError
    def initialize(group, section, idx)
      super "Missing the item #{idx + 1} in #{group}/#{section} words section"
    end
  end

  class FileNotFound < StandardError
    def initialize(filename)
      super "File not found: #{filename}"
    end
  end

  class MissingFiles < StandardError
    def initialize
      super 'No filenames specified'
    end
  end

  class ExistingFile < StandardError
    def initialize(filename)
      super "The file #{filename} already exists and won't be overwrite"
    end
  end

  class Interruption < StandardError
    def initialize
      super 'Ok ok... Exiting!'
    end
  end


  Differ.format = :color 

  Signal.trap('INT') { raise Interruption }

  Signal.trap('TERM') { raise Interruption }
end
