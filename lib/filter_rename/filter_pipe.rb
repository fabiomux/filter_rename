module FilterRename

  class FilterPipe
    attr_reader :source, :dest

    def initialize(fname, filters, cfg)
      # Filter params have to be reset for each file
      @cfg = cfg.filter.clone
      @source = FilenameFactory.create(fname, cfg.global)
      @dest = Marshal.load(Marshal.dump(@source))
      @filters = (filters.class == Array) ? filters : filters.filters
      @words = cfg.words
    end

    def changed?
      ! unchanged?
    end

    def unchanged?
      @source == @dest
    end
    alias_method :identical?, :unchanged?

    def diff
      @source.diff(@dest)
    end

    def apply

      @filters.each_with_index do |f, i|

        filter = f.keys.pop
        params = f.values.pop

        if [FilterRename::Filters::Config, FilterRename::Filters::Select].include? filter
          filter.new(@dest, cfg: @cfg, words: @words).filter(params)
        else
          filter.new(@dest, cfg: @cfg, words: @words).filter(params) unless skip?
        end

      end

      self
    end

    def rename!
      @source.rename!(@dest)
    end

    private

    def skip?
      if [:full_filename, :full_path, :filename].include? @cfg.grep_target.to_sym
        unmatched = instance_variable_get('@' + @cfg.grep_on.to_s).send(@cfg.grep_target.to_sym).match(Regexp.new(@cfg.grep)).nil?
      else
        unmatched = instance_variable_get('@' + @cfg.grep_on.to_s).get_string(@cfg.grep_target).match(Regexp.new(@cfg.grep)).nil?
      end

      @cfg.grep_exclude.to_s.to_boolean ? !unmatched : unmatched
    end

  end

end
