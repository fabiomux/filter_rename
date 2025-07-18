# frozen_string_literal: true

module FilterRename
  module Filters
    class Select < FilterBase
      def self.hint
        "Select the target where apply further transformations"
      end

      def self.params
        "name|ext|folder|..."
      end

      def filter(params)
        raise InvalidTarget, params[0] unless target? params[0].to_sym

        set_config :target, params[0].to_sym
      end
    end

    class Config < FilterBase
      def self.hint
        "Set config PARAM to VALUE"
      end

      def self.params
        "PARAM:VALUE[,PARAMS2:VALUE2,...]"
      end

      def filter(params)
        params.each do |par|
          set_config(par.split(":")[0], par.split(":")[1])
        end
      end
    end

    #------------------------

    class AddNumber < FilterNumber
      def self.hint
        "Add NUM to the NTH number"
      end

      def self.params
        "NTH,NUM"
      end

      def filtered_number(num, _param_num)
        num.to_i + params[1].to_i
      end
    end

    class AddNumberFrom < FilterNumber
      def self.hint
        "Add the number from TARGET to the NTH"
      end

      def self.params
        "NTH;TARGET"
      end

      def filtered_number(num, _param_num)
        num.to_i + get_string(params[1]).to_i
      end
    end

    class Append < FilterBase
      def self.hint
        "Append the TEXT to the current target"
      end

      def self.params
        "TEXT"
      end

      def filter(params)
        super "#{get_string}#{params[0]}"
      end
    end

    class AppendFrom < FilterBase
      def self.hint
        "Append the text from TARGET"
      end

      def self.params
        "TARGET"
      end

      def filter(params)
        super "#{get_string}#{get_string(params[0])}"
      end
    end

    class AppendAsWordTo < FilterBase
      def self.hint
        "Append the TEXT to TARGET as a word"
      end

      def self.params
        "TEXT,TARGET"
      end

      def filter(params)
        ws = get_config(:word_separator)
        set_string(get_string(params[1]).to_s.split(ws).push(params[0]).join(ws), params[1])
        super get_string
      end
    end

    class AppendTo < FilterBase
      def self.hint
        "Append the TEXT to TARGET"
      end

      def self.params
        "TEXT,TARGET"
      end

      def filter(params)
        set_string(get_string(params[1]).to_s + params[0], params[1])
        super get_string
      end
    end

    class AppendNumberTo < FilterNumber
      def self.hint
        "Append the NTH number to TARGET"
      end

      def self.params
        "NTH,TARGET"
      end

      def self_targeted?
        params[-1] == current_target
      end

      def filtered_number(num, _param_num)
        str = get_string(params[1])
        set_string("#{str}#{num}", params[1])
        num
      end
    end

    class AppendToNumber < FilterNumber
      def self.hint
        "Append the TEXT to the NTH number"
      end

      def self.params
        "NTH,TEXT"
      end

      def filtered_number(num, _param_num)
        "#{num}#{params[1]}"
      end
    end

    class AppendToWord < FilterWord
      def self.hint
        "Append the TEXT to the NTH word"
      end

      def self.params
        "NTH,TEXT"
      end

      def filtered_word(word, _param_num)
        word + params[1]
      end
    end

    class AppendWordFrom < FilterWord
      def self.hint
        "Append the NTH word from TARGET"
      end

      def self.params
        "NTH,TARGET"
      end

      def string_to_loop
        get_string(params[1])
      end

      def self_targeted?
        true
      end

      def filtered_word(word, _param_num)
        set_string([get_string, word].join(ws))
        word
      end
    end

    class AppendWordTo < FilterWord
      def self.hint
        "Append the NTH word to TARGET"
      end

      def self.params
        "NTH,TARGET"
      end

      def self_targeted?
        params[-1] == current_target
      end

      def filtered_word(word, _param_num)
        set_string([get_string(params[1]), word].join(ws), params[1])
        word
      end
    end

    class Capitalize < FilterBase
      def self.hint
        "Capitalize each word"
      end

      def self.params
        nil
      end

      def filter(_params)
        ws = get_config(:word_separator)
        super get_string.split(ws).map(&:capitalize).join(ws)
      end
    end

    class CapitalizeWord < FilterWord
      def self.hint
        "Capitalize the NTH word"
      end

      def self.params
        "NTH"
      end

      def filtered_word(word, _param_num)
        word.capitalize
      end
    end

    class CopyFrom < FilterBase
      def self.hint
        "Copy the text from TARGET"
      end

      def self.params
        "TARGET"
      end

      def filter(params)
        super get_string(params[0]).to_s
      end
    end

    class CopyNumberTo < FilterNumber
      def self.hint
        "Copy the NTH number to TARGET"
      end

      def self.params
        "NTH,TARGET"
      end

      def self_targeted?
        params[-1] == current_target
      end

      def filtered_number(num, _param_num)
        set_string(num, params[1])
        num
      end
    end

    class CopyOccurrenceTo < FilterOccurrence
      def self.hint
        "Copy the NTH occurrence of REGEX to TARGET"
      end

      def self.params
        "NTH,REGEX,TARGET"
      end

      def self_targeted?
        params[-1] == current_target
      end

      def filtered_occurrence(occurrence, _param_num)
        set_string(occurrence, params[-1])
        occurrence
      end
    end

    class CopyTo < FilterRegExp
      def self.hint
        "Copy the text selected by REGEX to TARGET"
      end

      def self.params
        "REGEX,TARGET"
      end

      def filtered_regexp(matches, params)
        if matches.length > 2
          matches[1..-1].each_with_index { |x, i| set_string(x, "#{params[1]}_#{i.next}") }
        else
          set_string(matches[1], params[1])
        end
        matches[0]
      end
    end

    class CopyWord < FilterWord
      def self.hint
        "Copy the NTH1 word to the NTH2 place"
      end

      def self.params
        "NTH1,NTH2"
      end

      def indexed_params
        2
      end

      def filtered_word(word, param_num)
        case param_num
        when 1
          @word = word
        when params_expanded.length
          word = [@word, word].join(ws)
        else
          @word = [@word, word].join(ws)
        end

        word
      end
    end

    class Delete < FilterRegExp
      def self.hint
        "Remove the text matching REGEX"
      end

      def self.params
        "REGEX"
      end

      def filtered_regexp(_matches, _params)
        ""
      end
    end

    class DeleteNumber < FilterNumber
      def self.hint
        "Remove the NTH number"
      end

      def self.params
        "NTH"
      end

      def filtered_number(_num, _param_num)
        ""
      end
    end

    class DeleteOccurrence < FilterOccurrence
      def self.hint
        "Delete the NTH occurrence of REGEXP"
      end

      def self.params
        "NTH,REGEXP"
      end

      def filtered_occurrence(_occurrence, _param_num)
        nil
      end
    end

    class DeleteWord < FilterWord
      def self.hint
        "Remove the NTH word"
      end

      def self.params
        "NTH"
      end

      def filtered_word(_word, _param_num)
        nil
      end
    end

    class FormatNumber < FilterNumber
      def self.hint
        "Format the NTH number adding leading zeroes to have LENGTH"
      end

      def self.params
        "NTH,LENGTH"
      end

      def filtered_number(num, _param_num)
        num.to_i.to_s.rjust(params[1].to_i, "0")
      end
    end

    class InsertAfterWord < FilterWord
      def self.hint
        "Insert the WORD after the NTH word"
      end

      def self.params
        "NTH,WORD"
      end

      def filtered_word(word, _param_num)
        [word, params[1]].join(ws)
      end
    end

    class InsertBeforeWord < FilterWord
      def self.hint
        "Insert the WORD after the NTH word"
      end

      def self.params
        "NTH,WORD"
      end

      def filtered_word(word, _param_num)
        [params[1], word].join(ws)
      end
    end

    class JoinNumbers < FilterNumber
      def self.hint
        "Join the numbers NTH1 and NTH2 and replace the NTH3 number with it"
      end

      def self.params
        "NTH1,NTH2,NTH3"
      end

      def indexed_params
        3
      end

      def filtered_number(number, param_num)
        case param_num
        when 1
          @number = number
          number = nil
        when params_expanded.length
          number = @number
        else
          @number += number
          number = nil
        end

        number
      end
    end

    class JoinWords < FilterWord
      def self.hint
        "Join the words NTH1 and NTH2 and replace the NTH3 word with it"
      end

      def self.params
        "NTH1,NTH2,NTH3"
      end

      def indexed_params
        3
      end

      def filtered_word(word, param_num)
        case param_num
        when 1
          @word = word
          word = nil
        when params_expanded.length
          word = @word
        else
          @word += word
          word = nil
        end

        word
      end
    end

    class LeftJustify < FilterBase
      def self.hint
        "Add enough CHAR(s) to the right side to have a N-length string"
      end

      def self.params
        "N,CHAR"
      end

      def filter(params)
        super get_string.ljust(params[0].to_i, params[1])
      end
    end

    class Lowercase < FilterBase
      def self.hint
        "Lowercase each word"
      end

      def self.params
        nil
      end

      def filter(_params)
        super get_string.downcase
      end
    end

    class LowercaseWord < FilterWord
      def self.hint
        "Lowercase the NTH word"
      end

      def self.params
        "NTH"
      end

      def filtered_word(word, _param_num)
        word.downcase
      end
    end

    class MoveTo < FilterRegExp
      def self.hint
        "Move the text selected by REGEX to TARGET"
      end

      def self.params
        "REGEX,TARGET"
      end

      def filtered_regexp(matches, params)
        if matches.length > 2
          matches[1..-1].each_with_index { |x, i| set_string(x, "#{params[1]}_#{i.next}") }
        else
          set_string(matches[1], params[1])
        end
        ""
      end
    end

    class MoveNumberTo < FilterNumber
      def self.hint
        "Move the NTH number to TARGET overwriting it"
      end

      def self.params
        "NTH,TARGET"
      end

      def self_targeted?
        params[-1] == current_target
      end

      def filtered_number(num, _param_num)
        set_string(num, params[1])
        ""
      end
    end

    class MoveOccurrenceTo < FilterOccurrence
      def self.hint
        "Move the NTH occurrence of REGEX to TARGET overwriting it"
      end

      def self.params
        "NTH,REGEX,TARGET"
      end

      def self_targeted?
        params[-1] == current_target
      end

      def filtered_occurrence(occurrence, _param_num)
        set_string(occurrence, params[-1])
        nil
      end
    end

    class MoveWord < FilterWord
      def self.hint
        "Move the NTH1 word to the NTH2 place"
      end

      def self.params
        "NTH1,NTH2"
      end

      def indexed_params
        2
      end

      def filtered_word(word, param_num)
        case param_num
        when 1
          @word = word
          res = nil
        when params_expanded.length
          res = [word, @word].join(ws)
        else
          @word = [@word, word].join(ws)
          res = nil
        end

        res
      end
    end

    class MoveWordTo < FilterWord
      def self.hint
        "Move the NTH word to TARGET overwriting it"
      end

      def self.params
        "NTH,TARGET"
      end

      def self_targeted?
        params[-1] == current_target
      end

      def filtered_word(word, _param_num)
        set_string(word, params[1])
        nil
      end
    end

    class MultiplyNumber < FilterNumber
      def self.hint
        "Multiply the NTH number with NUM"
      end

      def self.params
        "NTH,NUM"
      end

      def filtered_number(num, _param_num)
        num.to_i * params[1].to_i
      end
    end

    class Prepend < FilterBase
      def self.hint
        "Prepend the current target with TEXT"
      end

      def self.params
        "TEXT"
      end

      def filter(params)
        super "#{params[0]}#{get_string}"
      end
    end

    class PrependFrom < FilterBase
      def self.hint
        "Prepend the current target with the text from TARGET"
      end

      def self.params
        "TARGET"
      end

      def filter(params)
        super "#{get_string(params[0])}#{get_string}"
      end
    end

    class PrependToNumber < FilterNumber
      def self.hint
        "Prepend the TEXT to the NTH number"
      end

      def self.params
        "NTH,TEXT"
      end

      def filtered_number(num, _param_num)
        "#{params[1]}#{num}"
      end
    end

    class PrependToWord < FilterWord
      def self.hint
        "Prepend the TEXT to the NTH word"
      end

      def self.params
        "NTH,TEXT"
      end

      def filtered_word(word, _param_num)
        params[1] + word
      end
    end

    class PrependWordFrom < FilterWord
      def self.hint
        "Prepend with TARGET the NTH word"
      end

      def self.params
        "NTH,TARGET"
      end

      def string_to_loop
        get_string(params[1])
      end

      def self_targeted?
        true
      end

      def filtered_word(word, _param_num)
        set_string([word, get_string].join(ws))
        word
      end
    end

    class Replace < FilterRegExp
      def self.hint
        "Replace the text matching REGEX with REPLACE"
      end

      def self.params
        "REGEX,REPLACE"
      end

      def filtered_regexp(_matches, params)
        params[1]
      end
    end

    class ReplaceFrom < FilterRegExp
      def self.hint
        "Replace the REGEX matching text with the TARGET content"
      end

      def self.params
        "REGEX,TARGET"
      end

      def filtered_regexp(_matches, params)
        get_string(params[1]).to_s
      end
    end

    class ReplaceNumber < FilterNumber
      def self.hint
        "Replace the NTH number with NUMBER"
      end

      def self.params
        "NTH,NUMBER"
      end

      def filtered_number(_num, _param_num)
        params[1]
      end
    end

    class ReplaceOccurrence < FilterOccurrence
      def self.hint
        "Replace the NTH occurrence of REGEXP with TEXT"
      end

      def self.params
        "NTH,REGEXP,TEXT"
      end

      def filtered_occurrence(_occurrence, _param_num)
        params[2]
      end
    end

    class ReplaceWord < FilterWord
      def self.hint
        "Replace the NTH word with TEXT"
      end

      def self.params
        "NTH,TEXT"
      end

      def filtered_word(_word, _param_num)
        params[1]
      end
    end

    class ReplaceDate < FilterBase
      def self.hint
        "Replace a date from FORMATSRC to FORMATDEST (placeholders: <m>, <B>, <b>, <Y>, <d>)"
      end

      def self.params
        "FORMATSRC,FORMATDEST[,LANG]"
      end

      def filter(params)
        params[2] ||= get_config(:lang)
        super get_string.change_date_format(format_src: params[0], format_dest: params[1],
                                            long_months: get_words(:long_months, params[2]),
                                            short_months: get_words(:short_months, params[2]),
                                            long_days: get_words(:long_days, params[2]),
                                            short_days: get_words(:short_days, params[2]))
      end
    end

    class Reverse < FilterBase
      def self.hint
        "Reverse the string"
      end

      def self.params
        nil
      end

      def filter(_params)
        super get_string.reverse
      end
    end

    class RightJustify < FilterBase
      def self.hint
        "Apply enough CHAR(s) to the left side to have a N-length string"
      end

      def self.params
        "N,CHAR"
      end

      def filter(params)
        super get_string.rjust(params[0].to_i, params[1])
      end
    end

    class Set < FilterBase
      def self.hint
        "Set the current or an optional TARGET with TEXT"
      end

      def self.params
        "TEXT[,TARGET]"
      end

      def filter(params)
        if params[1].nil?
          str = params[0]
        else
          set_string(params[0], params[1].delete(":<>"))
          str = get_string
        end

        super str
      end
    end

    class SetWhen < FilterBase
      def self.hint
        "Set the current or given TARGET to TEXT when REGEX is matched"
      end

      def self.params
        "REGEX,TEXT[,TARGET]"
      end

      def filter(params)
        target = params[-1] if params.length.odd?
        set_string(params[1], target) if get_string =~ Regexp.new(params[0], get_config(:ignore_case).to_boolean)
        super get_string
      end
    end

    class Spacify < FilterBase
      def self.hint
        "Replace CHAR with a space"
      end

      def self.params
        "CHAR1,CHAR2,..."
      end

      def filter(params)
        regexp = Regexp.new(params.join("|"), get_config(:ignore_case).to_boolean)
        super get_string.gsub(regexp, " ")
      end
    end

    class SplitWord < FilterWord
      def self.hint
        "Split the NTH word using a REGEX with capturing groups"
      end

      def self.params
        "NTH,REGEX"
      end

      def filtered_word(word, _param_num)
        word.scan(Regexp.new(wrap_regex(params[1]), get_config(:ignore_case))).pop.to_a.join(ws)
      end
    end

    class Squeeze < FilterBase
      def self.hint
        "Squeeze consecutive CHARS in only one"
      end

      def self.params
        "CHAR"
      end

      def filter(params)
        super get_string.gsub Regexp.new("#{params[0]}{2,}", get_config(:ignore_case).to_boolean), params[0]
      end
    end

    class SwapNumber < FilterNumber
      def self.hint
        "Swap the NTH1 number with the NTH2"
      end

      def self.params
        "NTH1,NTH2"
      end

      def indexed_params
        2
      end

      def filtered_number(num, param_num)
        case param_num
        when 1
          @number = num.clone
          @last_number = get_string.get_number(params_expanded[-1].to_i)
          num = @last_number
        when params_expanded.length
          num = @number
        else
          @number = [@number, num].join(ns)
          num = @last_number
        end

        num
      end
    end

    class SwapWord < FilterWord
      def self.hint
        "Swap the NTH1 word with the NTH2"
      end

      def self.params
        "NTH1,NTH2"
      end

      def indexed_params
        2
      end

      def filtered_word(word, param_num)
        case param_num
        when 1
          @word = word.clone
          @last_word = get_string.split(ws)[params_expanded[-1]]
          word = @last_word
        when params_expanded.length
          word = @word
        else
          @word = [@word, word].join(ws)
          word = nil
        end

        word
      end
    end

    class Template < FilterBase
      def self.hint
        "Replace the <placeholders> in TEMPLATE with the relative targets"
      end

      def self.params
        "TEMPLATE"
      end

      def filter(params)
        super params[0].gsub(/<([a-z0-9_]+)>/) { get_string(Regexp.last_match[1]) }
      end
    end

    class Translate < FilterBase
      def self.hint
        "Replace text in GROUP from SUBGRPSRC to SUBGRPDST"
      end

      def self.params
        "GROUP,SUBGRPSRC,SUBGRPDST"
      end

      def filter(params)
        str = get_string
        group = params[0].to_sym
        lang_src = params[1] ? params[1].to_sym : :none
        lang_dest = params[2] ? params[2].to_sym : :none

        get_words(group, lang_src).each_with_index do |x, i|
          str = str.gsub(Regexp.new(x, get_config(:ignore_case)), get_words(group, lang_dest, i))
        end

        super str
      end
    end

    class Trim < FilterBase
      def self.hint
        "Remove trailing spaces"
      end

      def self.params
        nil
      end

      def filter(_params)
        super get_string.strip
      end
    end

    class Uppercase < FilterBase
      def self.hint
        "Uppercase each word"
      end

      def self.params
        nil
      end

      def filter(_params)
        super get_string.upcase
      end
    end

    class UppercaseWord < FilterWord
      def self.hint
        "Uppercase the NTH word"
      end

      def self.params
        "NTH"
      end

      def filtered_word(word, _param_num)
        word.upcase
      end
    end

    class Wrap < FilterRegExp
      def self.hint
        "Wrap the text matching REGEX with SEPARATOR1 and SEPARATOR2"
      end

      def self.params
        "REGEX,SEPARATOR1,SEPARATOR2"
      end

      def filtered_regexp(matches, params)
        "#{params[1]}#{matches[0]}#{params[2]}"
      end
    end

    class WrapWord < FilterWord
      def self.hint
        "Wrap the NTH word with SEPARATOR1 and SEPARATOR2"
      end

      def self.params
        "NTH,SEPARATOR1,SEPARATOR2"
      end

      def filtered_word(word, _param_num)
        "#{params[1]}#{word}#{params[2]}"
      end
    end
  end
end
