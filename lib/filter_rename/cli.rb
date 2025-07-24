# frozen_string_literal: true

require "optparse"
require "ostruct"
require "filter_rename"
require "filter_rename/version"

module FilterRename
  #
  # Parsing the input data.
  #
  class OptParseMain
    def self.parse(_args)
      options = Struct.new(:filters, :files, :global, :operation, :show_macro, :help_config).new
      options.filters = []
      options.files = []
      options.global = {}
      options.operation = :diff
      options.show_macro = ""
      options.help_config = ""

      opt_parser = OptionParser.new do |opt|
        opt.banner = "Usage: filter_rename [-g OPTION1[,OPTION2...]] [FILTER1[,FILTER2...]] <file1>" \
                     "[ <file2>...] OPERATION"

        opt.separator ""
        opt.separator "Operations:"

        opt.on("--apply", "Apply the changes.") do |_c|
          options.operation = :apply
        end

        opt.on("-d", "--dry-run", "Don't apply any change but check for errors") do |_c|
          options.operation = :dry_run
        end

        opt.on("-D", "--diff", "View the changes in a diff format [DEFAULT]") do |_c|
          options.operation = :diff
        end

        opt.on("-t", "--targets", "List of targets for each file") do |_c|
          options.operation = :targets
        end

        opt.on("-v", "--values", "List of targets values for each file") do |_c|
          options.operation = :values
        end

        opt.on("-g", "--globals", "List of global variables") do |_c|
          options.operation = :globals
        end

        opt.on("-c", "--configs", "List of filter variables") do |_c|
          options.operation = :configs
        end

        opt.on("-w", "--words", "List of groups of words available for translation") do |_c|
          options.operation = :words
        end

        opt.on("-m", "--macros", "List of available macros") do |_c|
          options.operation = :macros
        end

        opt.on("-s", "--show-macro <MACRO>", "List of commands used by MACRO") do |c|
          options.operation = :show_macro
          options.show_macro = c
        end

        opt.separator ""
        opt.separator "Options:"

        opt.on("--global OPTION:VALUE[,OPTION:VALUE]", 'Override global options with: "option:value"') do |v|
          v.parametrize.each do |idx|
            options.global.store(idx.split(":")[0].to_sym, idx.split(":")[1])
          end
        end

        opt.on("--virtual", "Accept a list of file not present in the local drives") do |_c|
          options.global.store(:mimemagic, false)
          options.global.store(:essential_tags, true)
          options.global.store(:check_source, false)
        end

        opt.separator ""
        opt.separator "Global options extended:"

        GlobalConfig::OPTIONS.each do |k, v|
          if v[:args].nil?
            opt.on("--[no-]g-#{k.to_s.gsub("_", "-")}", v[:desc]) do |c|
              options.global.store(k, c)
            end
          else
            opt.on("--g-#{k.to_s.gsub("_", "-")} #{v[:args]}", String, v[:desc]) do |c|
              options.global.store(k, c)
            end
          end
        end

        opt.separator ""
        opt.separator "Filter options extended:"

        FilterConfig::OPTIONS.each do |k, v|
          klass = Object.const_get("FilterRename::Filters::Config")

          if v[:args].nil?
            opt.on("--[no-]f-#{k.to_s.gsub("_", "-")}", v[:desc]) do |c|
              options.filters << { klass => ["#{k}:#{c}"] }
            end
          else
            opt.on("--f-#{k.to_s.gsub("_", "-")} #{v[:args]}", String, v[:desc]) do |c|
              options.filters << { klass => ["#{k}:#{c}"] }
            end
          end
        end

        opt.separator ""
        opt.separator "Filters:"

        opt.on("--macro MACRO1,[MACRO2,...]", Array, "Apply the MACRO") do |v|
          options.filters << MacroConfig.create(v)
        end

        Filters.constants.sort.each do |c|
          switch = c.to_s.to_switch
          klass = Object.const_get("FilterRename::Filters::#{c}")

          if klass.params.nil?
            opt.on("--#{switch}", klass.hint) do |v|
              options.filters << { klass => v }
            end
          elsif klass.params == Boolean
            opt.on("--[no-]#{switch}", klass.hint) do |v|
              options.filters << { klass => v }
            end
          else
            opt.on("--#{switch} #{klass.params}", klass.hint.to_s) do |v|
              options.filters << { klass => v.parametrize }
            end
          end
        end

        opt.separator ""
        opt.separator "Other:"

        opt.on_tail("-h", "--help", "Show this message") do
          puts opt
          exit
        end

        opt.on_tail("--help-config [G-OPTION|F-OPTION]", String,
                    "Extended description for the available options") do |o|
          options.operation = :help_config
          options.help_config = o
        end

        opt.on_tail("-v", "--version", "Show version") do
          puts VERSION
          exit
        end
      end

      if (!$stdin.tty? && !$stdin.closed?) || !ARGV.empty?
        opt_parser.parse!(ARGV)
        options.files = (ARGV.empty? ? ARGF : ARGV)
      else
        puts opt_parser
        exit
      end

      options
    end
  end

  #
  # Interface class to run the application.
  #
  class CLI
    def self.start
      options = OptParseMain.parse(ARGV)
      Builder.new(options).send(options.operation)
    rescue StandardError => e
      Messages.error e
      exit 1
    end
  end
end
