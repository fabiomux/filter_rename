require 'delegate'

module FilterRename

  # This is the class which handles the list
  # of filters.
  class FilterList
    attr_reader :filters

    def initialize(list)
      @filters = list
    end

    def expand_macros!(macro)

      @filters.each_with_index do |names , i|

        if FilterRename::MacroConfig == names.keys[0]
          z = 1
          names.values.pop.each do |n|
            macro.get_macro(n).each do |k, v|
              if v.nil? # Array
                @filters.insert(i + z, k.keys[0].to_s.to_filter => k[k.keys[0]])
              else # Hash
                @filters.insert(i + z, k.to_s.to_filter => v)
              end
              z += 1
            end
            @filters[i] = nil
          end
        end
      end

      @filters.delete_if(&:nil?)
    end

  end


  class FilterBase < SimpleDelegator

    def initialize(obj, options)
      super obj
      @dest = obj # useful for macros
      @cfg = options[:cfg]
      @words = options[:words]
    end

    def get_words(name, section, idx = nil)
      @words.get_words name, section, idx
    end

    def set_config(name, value)
      raise InvalidFilterSetting, name unless @cfg.instance_variables.include?("@#{name}".to_sym)

      @cfg.instance_variable_set ('@' + name.to_s), value
    end

    def get_config(name)
      raise InvalidFilterSetting, name unless @cfg.instance_variables.include?("@#{name}".to_sym)

      @cfg.instance_variable_get '@' + name.to_s
    end

    def filter(value)
      set_string value
    end

    def set_string(value, target = nil)
      if target.nil?
        super @cfg.target, value
      else
        super target, value
      end unless value.nil?
    end

    def get_string(target = nil)
      if target.nil?
        super @cfg.target
      else
        super target
      end
    end

    def match?(mask)
      get_string =~ Regexp.new(mask)
    end

    def wrap_regex(str)
      str = "(#{str})" unless str =~ /\(.*\)/
      str
    end

    def current_target
      @cfg.target.to_s
    end
  end


  module IndexedParams

    attr_reader :params, :params_expanded, :items

    def normalize_index(idx)
      max_length = items.length
      raise IndexOutOfRange, [idx, max_length] if idx.to_i > max_length || idx.to_i < -max_length

      if idx.to_i.positive?
        idx = idx.to_i.pred  # % max_length
      elsif idx.to_i.negative?
        idx = idx.to_i + max_length # % max_length
      end
      idx.to_i
    end

    def get_indexes
      indexes = []
      params_length = (indexed_params == 0) ? params.length : indexed_params

      params[0..params_length.pred].each do |x|
        if x =~ /\.\./
          indexes = indexes + Range.new(*(x.split('..').map { |y| normalize_index(y) })).map { |i| i }
        elsif x =~ /:/
          indexes = indexes + x.split(':').map { |y| normalize_index(y) }
        else
          indexes << normalize_index(x)
        end

      end

      indexes
    end

    def string_to_loop
      get_string
    end

    def indexed_params
      1
    end

    def self_targeted?
      false
    end

    def filter(params)
      @params = params
      @items = indexed_items
      @params_expanded = get_indexes

      res = loop_items

      if self_targeted?
        super get_string
      else
        super res
      end
    end
  end


  class FilterWord < FilterBase

    include IndexedParams


    private

    def ws
      get_config(:word_separator)
    end

    def indexed_items
      string_to_loop.split(ws)
    end

    def loop_items
      str = items.clone

      params_expanded.each_with_index do |idx, param_num|
        str[idx] = send :filtered_word, str[idx], param_num.next
      end

      str.delete_if(&:nil?).join(ws)
    end
  end


  class FilterNumber < FilterBase

    include IndexedParams


    private

    def ns
      get_config(:number_separator)
    end

    def indexed_items
      string_to_loop.get_numbers
    end

    def loop_items
      str = string_to_loop
      numbers = items.clone

      params_expanded.each_with_index do |idx, param_idx|
        numbers[idx] = self.send :filtered_number, numbers[idx], param_idx.next
      end
      str = str.map_number_with_index do |num, i|
        numbers[i]
      end

      str
    end
  end


  class FilterRegExp < FilterBase

    def filter(params)
      super loop_regex(get_string, params)
    end


    private

    def loop_regex(str, params)
      str = str.gsub(Regexp.new(wrap_regex(params[0]), get_config(:ignore_case).to_boolean)) do |x|
        matches = Regexp.last_match.clone
        self.send(:filtered_regexp, matches.to_a.delete_if(&:nil?), params).to_s.gsub(/\\([0-9]+)/) { |y| matches[$1.to_i] }
      end

      str
    end

  end

end
