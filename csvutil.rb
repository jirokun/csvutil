require 'csv'
require 'optparse'
require 'fileutils'

opt = OptionParser.new
opt.version = '0.0.1'
options = {}

opt.on('-t DATABASE', '--target=DATABASE', 'Target database, postgres | oracle', ['postgres', 'oracle']) {|v| options[:target] = v }
opt.on('-h', '--header', 'Specify this option when header is in CSV') {|v| options[:header] = v }
opt.on('-n table_name', '--name table_name', 'Table name to import') {|v| options[:table_name] = v }
opt.on('-f FILE', '--file=FILE', 'CSV file to input') {|v| options[:file] = v }

opt.parse(ARGV)
p options

raise "File must be specified" if options[:file].nil?
raise "File not found: #{options[:file]}" unless File.exists? options[:file]

WORK_DIR = 'work'

FileUtils.mkdir_p(WORK_DIR)

header_str = nil
open(options[:file], 'r', encoding: 'cp932') { |f| header_str = f.gets.chomp.encode('utf-8') }
header = CSV.parse_line(header_str)


if options[:target] == 'postgres'
  create_sql = "create table #{options[:table_name]} ("
  create_sql += header.map {|c| "#{c} varchar(1000)"}.join(',')
  create_sql += ");"
  open(WORK_DIR + "/1_create_table.sql", "w") do |f|
    f.puts create_sql
  end
  open(WORK_DIR + "/2_import_csv.sql", "w") do |f|
    f.puts "\\copy #{options[:table_name]}(#{header.join(',')}) from '#{options[:file]}' with encoding 'SJIS' header csv;"
  end
  open(WORK_DIR + "/3_drop_table.sql", "w") do |f|
    f.puts "drop table #{options[:table_name]};"
  end
  puts <<EOT
Please execute following commands.

# create table to insert
psql -h <host> -d <database> -U <user> < #{WORK_DIR}/1_create_table.sql
# import csv to table
psql -h <host> -d <database> -U <user> < #{WORK_DIR}/2_import_csv.sql
# drop table
psql -h <host> -d <database> -U <user> < #{WORK_DIR}/3_drop_table.sql
EOT

elsif options[:target] == 'oracle'
else
  STDERR.puts "Invalid usage. please #{$0} -h"
end
