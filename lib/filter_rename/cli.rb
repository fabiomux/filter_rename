require 'optparse'
require 'ostruct'
require 'filter_rename'
require 'filter_rename/version'

module FilterRename

  class OptParseMain

    def self.parse(args)
      options = OpenStruct.new
      options.filters = []
      options.files = []
      options.global = {}
      options.operation = :preview
      options.show_macro = ''

      opt_parser = OptionParser.new do |opt|
        opt.banner = 'Usage: filter_rename [-g OPTION1[,OPTION2...]] [FILTER1[,FILTER2...]] <file1>[ <file2>...] [OPERATION]'

        opt.separator ''
        opt.separator 'Operations:'

        opt.on('--apply', 'Apply the changes.') do |c|
          options.operation = :apply
        end

        opt.on('-d', '--dry-run', 'Don\'t apply any change but check for errors') do |c|
          options.operation = :dry_run
        end

        opt.on('-p', '--preview', 'Preview the filter chain applied [DEFAULT]') do |c|
          options.operation = :preview
        end

        opt.on('-t', '--targets', 'List of targets for each file') do |c|
          options.operation = :targets
        end

        opt.on('-g', '--globals', 'List of global variables') do |c|
          options.operation = :globals
        end

        opt.on('-c', '--configs', 'List of filter variables') do |c|
          options.operation = :configs
        end

        opt.on('-w', '--words', 'List of groups of words available for translation') do |c|
          options.operation = :words
        end

        opt.on('-m', '--macros', 'List of available macros') do |c|
          options.operation = :macros
        end

        opt.on('-s' , '--show-macro <MACRO>', 'List of commands used by MACRO') do |c|
          options.operation = :show_macro
          options.show_macro = c
        end

        opt.separator ''
        opt.separator 'Options:'

        opt.on('--global [OPTION:VALUE[,OPTION:VALUE]]', 'Override global options with: "option:value"') do |v|
          v.parametrize.each do |i|
            options.global.store(i.split(':')[0].to_sym, i.split(':')[1])
          end
        end

        opt.separator ''
        opt.separator 'Filters:'

        opt.on('--macro MACRO1,[MACRO2,...]', Array, 'Apply the MACRO' ) do |v|
          options.filters << MacroConfig.create(v) # { FilterRename::MacroConfig => v }
#           options.filters.merge MacroConfig.expand_macros(v)
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
            opt.on("--#{switch} #{klass.params}", "#{klass.hint}") do |v|
              options.filters << { klass => v.parametrize }
            end
          end
        end

        opt.separator ''
        opt.separator 'Other:'

        opt.on_tail('-h', '--help', 'Show this message') do
          puts opt
          exit
        end
        opt.on_tail('-v', '--version', 'Show version') do
          puts VERSION
          exit
        end
      end

      if (!STDIN.tty? && !STDIN.closed?) || !ARGV.empty?

        opt_parser.parse!(ARGV)

        (ARGV.empty? ? ARGF : ARGV).each do |f|
          f = File.expand_path(f.chomp)

          if File.exists?(f)
            options.files << f
          else
            raise FileNotFound, f
          end
        end if [:apply, :preview, :dry_run, :targets].include? options.operation
      else
        puts opt_parser; exit
      end

      options
    end

  end

  class CLI
    def self.start
      begin
        options = OptParseMain.parse(ARGV)
        Builder.new(options).send(options.operation)
      rescue => e
        Messages.error e
        exit 1
      end
    end
  end

end
