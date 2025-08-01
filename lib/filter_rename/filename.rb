# frozen_string_literal: true

module FilterRename
  #
  # Basic file attributes translated
  # to tags to be replaced.
  #
  class Filename
    attr_reader :original

    def self.writable_tags?
      false
    end

    def initialize(fname, cfg)
      @@count ||= cfg.counter_start
      @@count += 1
      @cfg = cfg

      @original = fname
      load_filename_data(fname)
    end

    def ==(other)
      full_filename == other.full_filename
    end

    def !=(other)
      full_filename != other.full_filename
    end

    def filename
      @name + @ext
    end

    def full_path
      if @folder.to_s.empty?
        @path
      else
        File.join [@path, @folder]
      end
    end

    def full_filename
      File.join [full_path, filename]
    end

    def set_string(target, str)
      instance_variable_set "@#{target}", str
    end

    def get_string(target)
      instance_variable_get "@#{target}"
    end

    def target?(target)
      instance_variables.include?(:"@#{target}")
    end

    def exists?
      File.exist?(full_filename)
    end

    def rename!(dest)
      old_data = {}

      if full_filename != dest.full_filename
        FileUtils.mkdir_p(dest.full_path) if full_path != dest.full_path && !(Dir.exist? dest.full_path)
        unless File.exist?(dest.full_filename)
          FileUtils.mv full_filename, dest.full_filename
          old_data = { full_filename: full_filename, full_path: full_path, filename: filename }
          load_filename_data(dest.full_filename)
        end
      end

      old_data
    end

    def calculate_hash(hash_type = :md5)
      raise UnknownHashCode, hash_type unless %i[sha1 sha2 md5].include?(hash_type.to_sym)

      klass = Object.const_get("Digest::#{hash_type.to_s.upcase}")
      klass.file(full_filename).to_s
    end

    def diff(dest)
      Differ.diff_by_word(dest.full_filename, full_filename).to_s
    end

    def pretty_size(size)
      i = 0
      size = size.to_i
      while (size >= 1024) && (i < FILE_SIZES.length)
        size = size.to_f / 1024
        i += 1
      end
      size.round(2).to_s.gsub(/.0$/, "") + FILE_SIZES[i]
    end

    def targets
      res = { readonly: [], writable: [] }
      instance_variables.each do |v|
        next if v == :@cfg

        res[instance_variable_get(v).writable? ? :writable : :readonly] << v.to_s.delete("@").to_sym
      end

      res
    end

    def writable?(tag)
      instance_variable_get(:"@#{tag}").writable?
    end

    def custom?(tag)
      instance_variable_get(:"@#{tag}").custom?
    end

    def values
      res = {}
      instance_variables.each do |v|
        next if v == :@cfg

        res[v.to_s.delete("@").to_sym] = instance_variable_get(v)
      end
      res
    end

    protected

    def metatag_to_var!(key, value, readonly: true)
      var_name = key.downcase.gsub(/[^a-z]/, "_").gsub(/_+/, "_")
      instance_variable_set("@#{var_name}", value.to_s.gsub("/", "_"))
      instance_variable_get("@#{var_name}").readonly! if readonly
    end

    private

    def load_filename_data(fname)
      @ext = File.extname(fname)
      @name = File.basename(fname, @ext)
      @path = File.dirname(File.expand_path(fname))
      @folder = File.basename(@path)
      @path = File.dirname(@path)

      # read only stuff
      @count = @@count.to_s.rjust(@cfg.counter_length.to_i, "0")

      if @cfg.essential_tags
        @count.readonly!
        [@ext, @name, @path, @folder, @path, @count, @original].map(&:basic!)
      else
        @ctime = File.ctime(fname).strftime(@cfg.date_format)
        @mtime = File.mtime(fname).strftime(@cfg.date_format)
        @size = File.size(fname).to_s
        @pretty_size = pretty_size(@size)

        [@count, @ctime, @mtime, @size, @pretty_size].map(&:readonly!)

        [@ext, @name, @path, @folder, @path, @count, @ctime, @size, @pretty_size, @original].map(&:basic!)

        metatag_to_var!("hash", calculate_hash(@cfg.hash_type), readonly: true) if @cfg.hash_on_tags
      end
    end
  end
end
