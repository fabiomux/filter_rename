require 'spec_helper'

RSpec.describe FilterRename do

  before(:all) do
    @config = FilterRename::Config.new
    @files = [
      'files/file_for_tests_1.txt',
      'files/file_for_tests_2.txt',
      'files/file_for_tests_3.txt',
    ].map { |x| File.join [Dir.pwd, 'spec', x] }
  end

  describe 'Word Filters' do

    context 'playing with words' do

      it 'move first word to last' do
        res = []
        @files.each do |src|
          src = FilterRename::FilenameFactory.create(src, @config.global)
          FilterRename::Filters::Spacify.new(src, cfg: @config.filter).filter(['_'])
          FilterRename::Filters::MoveWord.new(src, cfg: @config.filter).filter([1,-1])

          res << src.full_filename
        end

        expect(res).to eq([
          'files/for tests 1 file.txt',
          'files/for tests 2 file.txt',
          'files/for tests 3 file.txt',
        ].map { |x| File.join [Dir.pwd, 'spec', x] })
      end

      it 'move first two word to last' do
        res = []
        @files.each do |src|
          src = FilterRename::FilenameFactory.create(src, @config.global)
          FilterRename::Filters::Spacify.new(src, cfg: @config.filter).filter(['_'])
          FilterRename::Filters::MoveWord.new(src, cfg: @config.filter).filter(['1..2',-1])

          res << src.full_filename
        end

        expect(res).to eq([
          'files/tests 1 file for.txt',
          'files/tests 2 file for.txt',
          'files/tests 3 file for.txt',
        ].map { |x| File.join [Dir.pwd, 'spec', x] })
      end

      it 'append the first and third word to the end' do
        res = []
        @files.each do |src|
          src = FilterRename::FilenameFactory.create(src, @config.global)
          FilterRename::Filters::Spacify.new(src, cfg: @config.filter).filter(['_'])
          FilterRename::Filters::AppendWordFrom.new(src, cfg: @config.filter).filter(['1:3', 'name'])

          res << src.full_filename
        end

        expect(res).to eq([
          'files/file for tests 1 file tests.txt',
          'files/file for tests 2 file tests.txt',
          'files/file for tests 3 file tests.txt',
        ].map { |x| File.join [Dir.pwd, 'spec', x] })
      end
    end
  end

end
