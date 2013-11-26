#!/bin/env ruby
#
# find_haiku.rb
#
# Just a hack to detect haiku among regular English text. Tags sentences with
# exact 5/7/5 formation with 'PERFECT'. The underlying GCIDE dictionary doesn't
# have accurate syllable info for all words and is notably missing conjugations
# and plurals, so the script misses a lot and sometimes falsely identifies haiku
# using those bad syllable counts. Needs a human proofreader right now.
#
# TODO: refactor this damned ugly code.
#
# Usage: find_haiku.rb <file.pdf|file.txt>
#
# Requires `xpdf` for the `pdftotext` program.
# Requires a `words.sqlite3` DB with a `words (word, word_raw, syllable_count,
#   is_accurate)` table built from GCIDE files. See `load_gcide.rb`.
#
require 'pathname'
require 'sqlite3'
require 'scalpel'

INCLUDE_IMPERFECT = true
puts 'Include imperfect haiku sentences: ' + INCLUDE_IMPERFECT.to_s

class BadSyllablesError < StandardError; end

db = SQLite3::Database.open('words.sqlite3')
find_word = db.prepare 'SELECT * FROM words WHERE word = ?'

def snarf words, syllable_count
  line = []
  syllables = 0
  words.dup.each do |word|
    line << word[:word]
    syllables += word[:syllable_count]
    words.shift
    raise BadSyllablesError if syllables > syllable_count
    return line.join(' ') if syllables == syllable_count
  end
  raise BadSyllablesError
end

file = ARGV.shift
unless File.exist?(file.to_s)
  STDERR.puts "Usage: #{$0} <file>"
  exit 1
end

file = Pathname.new(file)

case file.extname.downcase
  when '.pdf'
    `pdftotext -v 2>&1`
    if [0, 99].include?($?.exitstatus)
      text = `pdftotext "#{file}" -`
    else
      STDERR.puts 'Please install xpdf to process PDF files (pdftotext required)'
      exit 1
    end
  when '.txt'
    text = File.read(file)
end

sentences = Scalpel.cut(text)

sentences.each do |sentence|
  sentence = sentence.gsub(/[\n\r]/, ' ').gsub(/[^A-Za-z\s]/, '').gsub(/\s+/, ' ')
  words = sentence.split(/\s+/)
  words = words.map { |word|
    stats = find_word.execute(word.downcase).to_a.first
    { word: word,
      syllable_count: stats ? stats[2] : 0 }
  }
  total_syllable_count = words.inject(0) { |sum, word| sum + word[:syllable_count] }
  haiku = []
  if words.all? { |word| word[:syllable_count] > 0 }
    begin
      haiku[0] = snarf(words, 5)
      haiku[1] = snarf(words, 7)
      haiku[2] = snarf(words, 5)
    rescue BadSyllablesError
      haiku = []
    end

    is_perfect = total_syllable_count == 17 && !haiku.empty?

    if is_perfect || INCLUDE_IMPERFECT && !haiku.empty?
      puts
      puts 'PERFECT:' if total_syllable_count == 17 && INCLUDE_IMPERFECT
      puts haiku.join("\n")
    end
  end
end
