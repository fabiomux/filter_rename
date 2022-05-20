require 'mp3info'

module FilterRename

  class Mp3Filename < Filename

    def self.has_writable_tags
      true
    end

    def initialize(fname, cfg)
      super fname, cfg

      load_mp3_data(fname)
    end

    def ==(dest)
      super &&
      ([ @title, @artist, @album, @track, @comments, @year, @genre, @genre_s ] ==
       [ dest.get_string(:title), dest.get_string(:artist), dest.get_string(:album), dest.get_string(:track),
         dest.get_string(:comments), dest.get_string(:year), dest.get_string(:genre), dest.get_string(:genre_s) ])
    end

    def rename!(dest)
      old_data = super dest

      Mp3Info.open(full_filename) do |mp3|
        old_data.merge!({ title: mp3.tag.title, artist: mp3.tag.artist, album: mp3.tag.album,
                          tracknum: mp3.tag.tracknum, comments: mp3.tag.comments, year: mp3.tag.year,
                          genre: mp3.tag.genre, genre_s: mp3.tag.genre_s })

        mp3.tag.title = dest.get_string(:title)
        mp3.tag.artist = dest.get_string(:artist)
        mp3.tag.album = dest.get_string(:album)
        mp3.tag.tracknum = dest.get_string(:track)
        mp3.tag.comments = dest.get_string(:comments).to_s
        mp3.tag.year = dest.get_string(:year)
        mp3.tag.genre = dest.get_string(:genre).to_i % 256 
        mp3.tag.genre_s = dest.get_string(:genre_s)
      end

      load_mp3_data(full_filename)

      old_data
    end

    def diff(dest)
      super(dest) + "
       Title:    #{Differ.diff_by_word(dest.get_string(:title).to_s, @title.to_s)}
       Artist:   #{Differ.diff_by_word(dest.get_string(:artist).to_s, @artist.to_s)}
       Album:    #{Differ.diff_by_word(dest.get_string(:album).to_s, @album.to_s)}
       Track:    #{Differ.diff_by_word(dest.get_string(:track).to_s, @track.to_s)}
       Comments: #{Differ.diff_by_word(dest.get_string(:comments).to_s, @comments.to_s)}
       Year:     #{Differ.diff_by_word(dest.get_string(:year).to_s, @year.to_s)}
       Genre:    #{Differ.diff_by_word(dest.get_string(:genre).to_s, @genre.to_s)}
       GenreS:   #{Differ.diff_by_word(dest.get_string(:genre_s).to_s, @genre_s.to_s)}
       "
    end


    private

    def load_mp3_data(fname)
      mp3info = Mp3Info.new(fname)
      @title = mp3info.tag.title.to_s
      @artist = mp3info.tag.artist.to_s
      @album = mp3info.tag.album.to_s
      @track = mp3info.tag.tracknum.to_i
      @comments = mp3info.tag.comments.to_s
      @year = mp3info.tag.year.to_i
      @genre = mp3info.tag.genre.to_i
      @genre_s =  mp3info.tag.genre_s.to_s

      # read only stuff
      @vbr = (mp3info.tag.vbr ? 'vbr' : '')
      @samplerate = mp3info.samplerate.to_s
      @bitrate = mp3info.bitrate.to_s

      [@vbr, @samplerate, @bitrate].map(&:readonly!)
    end

  end

end
