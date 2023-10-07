# frozen_string_literal: true

require "taglib"

module FilterRename
  #
  # Mp3 files tags handling.
  #
  class AudioFilename < Filename
    def self.writable_tags?
      true
    end

    def initialize(fname, cfg)
      super fname, cfg

      load_audio_data(fname)
    end

    def ==(other)
      super &&
        ([@title, @artist, @album, @track, @comment, @year, @genre] ==
         [other.get_string(:title), other.get_string(:artist), other.get_string(:album), other.get_string(:track),
          other.get_string(:comment), other.get_string(:year), other.get_string(:genre)])
    end

    def rename!(dest)
      old_data = super dest

      TagLib::FileRef.open(full_filename) do |audio|
        old_data.merge!({ title: audio.tag.title, artist: audio.tag.artist, album: audio.tag.album,
                          track: audio.tag.track, comment: audio.tag.comment, year: audio.tag.year,
                          genre: audio.tag.genre })

        audio.tag.title = dest.get_string(:title)
        audio.tag.artist = dest.get_string(:artist)
        audio.tag.album = dest.get_string(:album)
        audio.tag.track = dest.get_string(:track)
        audio.tag.comment = dest.get_string(:comment).to_s
        audio.tag.year = dest.get_string(:year)
        audio.tag.genre = dest.get_string(:genre)

        audio.save
      end

      load_audio_data(full_filename)

      old_data
    end

    def diff(dest)
      super(dest) + "
       Title:    #{Differ.diff_by_word(dest.get_string(:title).to_s, @title.to_s)}
       Artist:   #{Differ.diff_by_word(dest.get_string(:artist).to_s, @artist.to_s)}
       Album:    #{Differ.diff_by_word(dest.get_string(:album).to_s, @album.to_s)}
       Track:    #{Differ.diff_by_word(dest.get_string(:track).to_s, @track.to_s)}
       Comments: #{Differ.diff_by_word(dest.get_string(:comment).to_s, @comment.to_s)}
       Year:     #{Differ.diff_by_word(dest.get_string(:year).to_s, @year.to_s)}
       Genre:    #{Differ.diff_by_word(dest.get_string(:genre).to_s, @genre.to_s)}
       "
    end

    private

    def load_audio_data(fname)
      audioinfo = TagLib::FileRef.new(fname, true, TagLib::AudioProperties::Average)
      @title = audioinfo.tag.title.to_s
      @artist = audioinfo.tag.artist.to_s
      @album = audioinfo.tag.album.to_s
      @track = audioinfo.tag.track.to_i
      @comment = audioinfo.tag.comment.to_s
      @year = audioinfo.tag.year.to_i
      @genre = audioinfo.tag.genre.to_s

      # read only stuff
      @duration = audioinfo.audio_properties.length_in_seconds.to_s
      @hduration = format "%<h>dh%<m>dm%<s>2ds", { h: @duration.to_i / 3600,
                                                   m: @duration.to_i / 60 % 60,
                                                   s: @duration.to_i % 60 }
      @samplerate = audioinfo.audio_properties.sample_rate.to_s
      @bitrate = audioinfo.audio_properties.bitrate.to_s

      [@duration, @hduration, @samplerate, @bitrate].map(&:readonly!)
    end
  end
end
