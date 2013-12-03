#!/bin/env ruby
#
# load_gcide.rb
#
# Lightning-fast loader to transform GCIDE dictionary quasi-XML into a syllable
# count database. Reads `CIDE.*` and writes `words.sqlite3`.
#
# NOTE: GCIDE lacks conjugations, plurals, words, and sometimes falsely notates
#   polysyllabic words as monosyllabic. User beware.
#
# Grab GCIDE data files at: http://ftp.gnu.org/gnu/gcide/
#
require 'sqlite3'

db = SQLite3::Database.open('words.sqlite3')

db.execute "PRAGMA synchronous=OFF"
db.execute "PRAGMA count_changes=OFF"
db.execute "PRAGMA journal_mode=MEMORY"
db.execute "PRAGMA temp_store=MEMORY"
db.execute "PRAGMA auto_vacuum=FULL"

db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS words (
    word STRING,
    word_raw STRING,
    syllable_count INTEGER,
    is_accurate BOOLEAN
  );
SQL
db.execute 'DELETE FROM words;'
stmt = db.prepare('INSERT INTO words VALUES (?, ?, ?, ?);')

Dir['CIDE.*'].each do |file|
  print "#{file}: "
  doc = File.read(file).force_encoding("ISO-8859-1").encode("utf-8", replace: nil)
  words = doc.scan(/<hw>(.*?)<\/hw>/).flatten.map(&:downcase).reject { |w| w.match(/[0-9]/) }
  word_stats = words.map { |word|
    [ word.gsub(/[^A-Za-z]/, ''),
      word,
      word.split(/[^A-Za-z]/).reject(&:empty?).length,
      word.match(/[^A-Za-z]/) ? 1 : 0 ]
  }
  word_stats.uniq!(&:first)
  puts "#{word_stats.length} words"
  db.execute 'BEGIN TRANSACTION'
  word_stats.each_with_index do |stats, idx|
    print '.' if idx % 5 == 0
    stmt.execute *stats
  end
  db.execute 'COMMIT TRANSACTION'
  puts
end

db.execute 'CREATE INDEX word_index ON words (word);'
