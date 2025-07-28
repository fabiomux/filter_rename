# frozen_string_literal: true

require "spec_helper"

RSpec.describe FilterRename do
  before(:all) do
    @config = FilterRename::Config.new
    @files = [
      "files/file_for_tests_1.txt",
      "files/file_for_tests_2.txt",
      "files/file_for_tests_3.txt"
    ].map { |x| File.join [Dir.pwd, "spec", x] }
  end

  describe "Word Filters" do
    context "playing with words" do
      it "move first word to the end" do
        res = []
        filters = FilterRename::FilterList.new [
          { FilterRename::Filters::Spacify => ["_"] },
          { FilterRename::Filters::MoveWord => [1, -1] }
        ]
        @files.each do |src|
          fp = FilterRename::FilterPipe.new(src, filters, @config).apply

          res << fp.dest.full_filename
        end

        expect(res).to eq([
          "files/for tests 1 file.txt",
          "files/for tests 2 file.txt",
          "files/for tests 3 file.txt"
        ].map { |x| File.join [Dir.pwd, "spec", x] })
      end

      it "move first two word to the end" do
        res = []
        filters = FilterRename::FilterList.new [
          { FilterRename::Filters::Spacify => ["_"] },
          { FilterRename::Filters::MoveWord => ["1..2", -1] }
        ]
        @files.each do |src|
          fp = FilterRename::FilterPipe.new(src, filters, @config).apply

          res << fp.dest.full_filename
        end

        expect(res).to eq([
          "files/tests 1 file for.txt",
          "files/tests 2 file for.txt",
          "files/tests 3 file for.txt"
        ].map { |x| File.join [Dir.pwd, "spec", x] })
      end

      it "append the first and third word to the end using the name target" do
        res = []
        filters = FilterRename::FilterList.new [
          { FilterRename::Filters::Spacify => ["_"] },
          { FilterRename::Filters::AppendWordFrom => ["1:3", "name"] }
        ]
        @files.each do |src|
          fp = FilterRename::FilterPipe.new(src, filters, @config).apply

          res << fp.dest.full_filename
        end

        expect(res).to eq([
          "files/file for tests 1 file tests.txt",
          "files/file for tests 2 file tests.txt",
          "files/file for tests 3 file tests.txt"
        ].map { |x| File.join [Dir.pwd, "spec", x] })
      end

      it "move the second word to tmp target and append back to the end" do
        res = []
        filters = FilterRename::FilterList.new [
          { FilterRename::Filters::Spacify => ["_"] },
          { FilterRename::Filters::MoveWordTo => %w[2 tmp] },
          { FilterRename::Filters::Append => [" "] },
          { FilterRename::Filters::AppendFrom => ["tmp"] }
        ]
        @files.each do |src|
          fp = FilterRename::FilterPipe.new(src, filters, @config).apply

          res << fp.dest.full_filename
        end

        expect(res).to eq([
          "files/file tests 1 for.txt",
          "files/file tests 2 for.txt",
          "files/file tests 3 for.txt"
        ].map { |x| File.join [Dir.pwd, "spec", x] })
      end

      it "move the first two words to tmp target and append back to the end" do
        res = []
        filters = FilterRename::FilterList.new [
          { FilterRename::Filters::Spacify => ["_"] },
          { FilterRename::Filters::MoveWordTo => ["1..2", "tmp"] },
          { FilterRename::Filters::Append => [" "] },
          { FilterRename::Filters::AppendFrom => ["tmp"] }
        ]
        @files.each do |src|
          fp = FilterRename::FilterPipe.new(src, filters, @config).apply

          res << fp.dest.full_filename
        end

        expect(res).to eq([
          "files/tests 1 file for.txt",
          "files/tests 2 file for.txt",
          "files/tests 3 file for.txt"
        ].map { |x| File.join [Dir.pwd, "spec", x] })
      end
    end
  end
end
